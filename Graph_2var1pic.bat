@rem = ' 2変数のグラフ化　Graph_2var1pic.bat　$ARGV[2]ファイル名1 [3]変数名1 [4]ファイル名2 [5]変数名2 [6]調整係数

@echo off

set INPUT=GRAPH2
set OUTPUT=GRAPH3
set FILE1=IAMCTemplate_i_past.csv
set FILE2=IAMCTemplate_i_future.csv

rmdir /s /q %OUTPUT%
mkdir %OUTPUT%

for %%v in (GDP_Capita Energy_Intensity Carbon_Intensity Electricity_Rate_Total) do (
	mkdir %OUTPUT%\%%v
	perl %0 %INPUT% %OUTPUT%\%%v %FILE1% %%v %FILE2% %%v 2010 > %OUTPUT%\%%v\log_%%v.txt
	perl %0 %INPUT% %OUTPUT%\%%v %FILE1% ChangeRate_%%v %FILE2% ChangeRate_%%v 0 > %OUTPUT%\%%v\log_ChangeRate_%%v.txt
	start %OUTPUT%\%%v\log_%%v.txt
	start %OUTPUT%\%%v\log_ChangeRate_%%v.txt
)

goto endofperl
@rem ' ;

# batコマンド 仮置き

# for %%v in (Energy_Intensity Carbon_Intensity ) do (
# 	mkdir %OUTPUT%\%%v
# 	perl %0 %INPUT% %OUTPUT%\%%v %FILE1% %%v %FILE2% %%v %ADJUST% > %OUTPUT%\%%v\log_%%v.txt
# 	perl %0 %INPUT% %OUTPUT%\%%v %FILE1% ChangeRate_%%v %FILE2% ChangeRate_%%v %ADJUST% > %OUTPUT%\%%v\log_ChangeRate_%%v.txt
# 	start %OUTPUT%\%%v\log_%%v.txt
# 	start %OUTPUT%\%%v\log_ChangeRate_%%v.txt
# )

# for %%v in (Electricity_Rate_Total Electricity_Rate_Ind Electricity_Rate_Tra Electricity_Rate_Res Electricity_Rate_Com Electricity_Rate_AgFo ) do (
# )


# set VAR=Energy_Intensity

# mkdir %OUTPUT%\%VAR%
# perl %0 %INPUT% %OUTPUT%\%VAR% %FILE1% %VAR% %FILE2% %VAR% %ADJUST% > %Hesate_%VAR% %ADJUST% > %OUTPUT%\%VAR%\log_ChangeRate_%VAR%.txt
# start %OUTPUT%\%VAR%\log_%VAR%.txt
# start %OUTPUT%\%VAR%\log_ChangeRate_%VAR%.txt


# mkdir %OUTPUT%\EI
# perl %0 %INPUT% %OUTPUT%\EI "IAMCTemplate_out.csv" "Energy_Intensity" "IAMCTemplate.csv" "Energy Intensity" "2010" > %OUTPUT%\EI\log_Energy_Intensity.txt
# start %OUTPUT%\EI\log_Energy_Intensity.txt

# for %%s in (Total) do (
# 	mkdir %OUTPUT%\CI_%%s
# 	perl %0 %INPUT% %OUTPUT%\CI_%%s "IAMCTemplate_out.csv" Carbon_Intensity_%%s "IAMCTemplate.csv" "Carbon Intensity" "2010" > %OUTPUT%\CI_%%s\log_Carbon_Intensity_%%s.txt
# 	start %OUTPUT%\CI_%%s\log_Carbon_Intensity_%%s.txt
# )

# for %%s in (Total) do (
# 	mkdir %OUTPUT%\ER_%%s
# 	perl %0 %INPUT% %OUTPUT%\ER_%%s "IAMCTemplate_out.csv" Electricity_Rate_%%s "IAMCTemplate.csv" "Electrification rate (Ele^/TFC)" "2010" > %OUTPUT%\ER_%%s\log_Electricity_Rate_%%s.txt
# 	start %OUTPUT%\ER_%%s\log_Electricity_Rate_%%s.txt
# )

# perl %0 $ARGV[0]入力フォルダ＝%INPUT% [1]出力フォルダ＝%OUTPUT%\EI $ARGV[2]ファイル名1 [3]変数名1 [4]ファイル名2 [5]変数名2 [6]調整係数 > ログファイル＝%OUTPUT%\EI\log_Energy_Intensity.txt



#! /usr/local/bin/perl
# Graph_2row21pic.pl	2系統のデータを重ねてグラフ出力

#==========
# 構成
#==========
#     
#     +-- here / Graph_2rows1pic.bat  	このファイル、計算の本体
#			|
#			+-- REF2 	参照データ用フォルダ
#			|			IAMCTemplate.csv		2010年～    	タイトル行が1行目
#			|			IAMCTemplate_ref.csv	1960～2019年	同上
#			|									
#			+-- GRAPH2 	出力用フォルダ
#				 		log.txt					エラー等の確認ファイル
#				 		(変数名)_シナリオ名_地域名1.gif
#				 		(変数名)_シナリオ名_地域名2.gif
#				 		(変数名)_シナリオ名_地域名n.gif

#=============
# フロー
#=============

# (1) IAMCTemplate_out.csv(ref)読込　＞ タイトル行取得@years_ref ＞ 条件マッチ($VARIABLE/$SCENARIO)＞ データ行取得@var_ref
# (2) IAMCTemplate.csv(future)読込　＞ タイトル行取得@years ＞ 条件マッチ($VARIABLE/$SCENARIO)＞ データ行取得@var
# (3) (@var), (@var_ref) を基準年値で正規化する
# (4) (@var), (@var_ref) が同時プロットされたグラフファイルの出力

#=============
# 設定
#=============

use strict;
use warnings;
use GD::Graph::linespoints;
use GD::Graph::points;
use File::Path;

@ARGV = map { $_ =~ s/\^//ig; $_ } @ARGV; 	# batコマンド用のエスケープ文字(^)の削除

#　$ARGV[2]ファイル名1 [3]変数名1 [4]ファイル名2 [5]変数名2 [6]調整係数

my $reference_derectory = "$ARGV[0]";	# "REF2";	# 参照データの場所、CSV前提（そのうち形式SWITCHにする）
my $result_derectory = "$ARGV[1]";	# "GRAPH2";	# 結果データの場所、CSV前提（同上）

my @files = ("$ARGV[2]", "$ARGV[4]");

my @variables_ref = "$ARGV[3]";
my @variables = "$ARGV[5]";
my $BaseYear = "$ARGV[6]";	# 基準年　# 無効にする場合は0　

# フォーマット指定
my @title_line  = qw( MODEL SCENARIO REGION VARIABLE UNIT );	# yearの前までの配列
# my @regions = qw( USA CHN JPN );
my @regions = qw( XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF );	# 地域の配列　qw( USA XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF ASIA2 World );

# my @files = qw( IAMCTemplate_out.csv IAMCTemplate.csv ); 	# 参照用データ　評価対象のデータ [0]番はRef IAMCTemplate_ref.csv

my @scenarios = qw( Baseline 2C ); 	# シナリオの配列 qw( Baseline 1.5C 2C 2.5C WB2C );
my @scenarios_ref = qw( Reference ); 	# REFシナリオの配列 @scenariosに対応、省略時は[0]の値


#=============
# 準備
#=============

# rmtree($result_derectory);
# mkdir $result_derectory or die "$result_derectory を作成することができません。 : $!";
# open(STDOUT,">$result_derectory/log.txt");
chdir $reference_derectory;

my ($line, @line);
my (@years, @var, @title_char);	# グラフに渡すデータ
my (@years_ref, @var_ref );	# グラフに渡すデータ
my ($year, %var, %var_ref);	# 連続年に変換するためのハッシュと年キー、$var{$year}, $var_ref{$year}
my ($file, $region, $variable, $variable_no, $scenario, $scenario_no ) = undef; 	# loop中で使う変数

print "\@ARGV : @ARGV \n"; 	# 確認用出力
print "\@variables : @variables \n"; 	# 確認用出力
print "\@variables_ref : @variables_ref "; 	# 確認用出力
print "\t NO MATCH!! " unless ( $#variables == $#variables_ref );
print "\n"; 	# 確認用出力

foreach (0..$#scenarios) { $scenarios_ref[$_] = $scenarios_ref[$#scenarios_ref] unless ( $scenarios_ref[$_] ); }
print "\@scenarios : @scenarios \n"; 	# 確認用出力
print "\@scenarios_ref : @scenarios_ref \n"; 	# 確認用出力

#=============
# 1条件の処理		# 変数、シナリオ、地域のセット
#=============

foreach $variable_no(0..$#variables) { 	# 変数でloop

foreach $scenario_no(0..$#scenarios) { 	# シナリオでloop
foreach $region(@regions) { 	# 地域でloop

	print "\n\n【START】 \t variable : $variables[$variable_no] \t scenario : $scenarios[$scenario_no] \t region : $region \n"; 	# 確認用出力

	foreach $file(@files) { 	# ファイルでloop

		(@years, @var, @title_char) = undef;	# 初期化

		open(IN,"$file");
		$line = <IN>;	# 先頭行の読込　年タイトル行
		$line =~ s/\"(\b.*?\b)\"/$1/ig;	# 最小マッチ　 "*", パターン
		chomp ($line);
		@line = split(/\,/, $line);	# とりあえずカンマで区切る
		@years = @line[$#title_line+1..$#line]; 	# タイトル行から年を取得

		print "\n\$file : $file \n \@years : @years \n"; 	# 確認用出力

		# 基準年処理（元の場所）

		# 過去Refか将来シナリオかでマッチ対象となるシナリオ名/変数名を入れ替える　$files[0]ならRef
		if ( $file eq $files[0] ) { # Ref Past
			$scenario = $scenarios_ref[$scenario_no];
			$variable = $variables_ref[$variable_no];
		} else { # Future
			$scenario = $scenarios[$scenario_no];
			$variable = $variables[$variable_no];
		}

		while (<IN>) {	#データ行の処理開始

			s/\"(\b.*?\b)\"/$1/ig;	# 最小マッチ　 "*", パターン
			chomp;
			@line = split(/\,/);	# とりあえずカンマで区切る
#			print "\n \@line : @line \t"; 	# 確認用出力

			unless ( $line[1] ) { 
				next; 
			}
			if ( ($line[1] eq $scenario)&&($line[2] eq $region)&&($line[3] eq $variable) ) { 
				# VARIABLE SCENARIO region が一致したら
				@var = @line[$#title_line+1..$#line]; 	# 年に相当する値を取得
				@title_char = @line[0..$#title_line]; 	# ヒットした行のタイトルを取得
				last;
			}

		} 	# #データ行の処理ここまで
		close(IN);

		# 基準年処理：：準備＜ここから＞
		my $BaseYear_num = "none"; 	# 基準年値の配列番号、@years の中で 基準年が何番目か
		while ( my ($i,$j) = each @years ) {
			$BaseYear_num = $i if ($j==$BaseYear); 
		}
		if ( $BaseYear_num eq "none" ) { 	# 初期値のままなら、エラー出力
			print "【基準年($BaseYear)が、入力データに含まれていません】 \n"; 
		} else {
			print "【基準年値は $BaseYear_num 番目の要素です】\n" ;
		}
		# 基準年処理：：準備＜ここまで＞
		# 基準年値で正規化する処理（移動後）
		if ($BaseYear) {
			my $val_baseYear = $var[$BaseYear_num];
			if ( $val_baseYear ) { # 基準年の値が存在する場合
				foreach (@var) { $_ =  $_ / $val_baseYear; }
				# @var = map { $_ / $val_baseYear } @var; 	# 9/16 変更
				$title_char[4] .= " (val($BaseYear)\=1\.0)";
			} else {
				print "【基準年値が、存在しません】\n";
			}
		}  # ＜ここまで＞基準年値で正規化する処理

		if ( $file eq $files[0] ) { 	# 参照データのXY値を別変数に格納する
			@years_ref = @years;
			@var_ref = @var;
		}

	} 	# ファイルでloop

	# ここで データをGraph に渡す

	print "\n\$region : $region \n"; 	# 確認用出力
	print "\@years : @years \n"; 	# 確認用出力
	print "\@years_ref : @years_ref \n"; 	# 確認用出力
	print "\@var : @var \n"; 	# 確認用出力
	print "\@var_ref : @var_ref \n"; 	# 確認用出力

	# グラフ用ハッシュ（年をキーとして値を返す）の作成
	(%var, %var_ref)= undef;	# グラフに渡すためのハッシュ、$var{$year}

	foreach (0..$#years) { 	# 年でloop
		$var{$years[$_]} = $var[$_];
	} 	# 年でloop

	foreach (0..$#years_ref) { 	# 年でloop
		$var_ref{$years_ref[$_]} = $var_ref[$_];
	} 	# 年でloop

	# 各年の配列に変換する

	my @years_sort = uniq(sort(@years, @years_ref)); 	
	my $years_min = $years_sort[0]; 	# 
	my $years_max = $years_sort[$#years_sort]; 	# 

	my (@eachyear, @var_eachyear, @var_ref_eachyear ) = undef;
	my $i;
	for ( $i=0; $i<=$years_max-$years_min ; $i++ ) { 
		$eachyear[$i] = $years_min + $i;
		if ( $var{$eachyear[$i]} ) { 
			$var_eachyear[$i] = $var{$eachyear[$i]}; 
		} else {
			$var_eachyear[$i] = undef; 
		}
		if ( $var_ref{$eachyear[$i]} ) { 
			$var_ref_eachyear[$i] = $var_ref{$eachyear[$i]}; 
		} else {
			$var_ref_eachyear[$i] = undef; 
		}
#		print "\$i:$i \t \$eachyear[$i]:$eachyear[$i] \t \$var_eachyear[$i]:$var_eachyear[$i] \t \$var_ref_eachyear[$i]:$var_ref_eachyear[$i] \n"; 	# 確認用出力 ＜削除禁止/不要時はコメントアウト＞

	}

	# グラフ渡し用配列の確認
	print "\n＜年変換の直後の確認＞\n"; 	# 確認用出力
	print "\$years_min : $years_min \n"; 	# 確認用出力
	print "\$years_max : $years_max \n"; 	# 確認用出力
	print "\@years : @years \n"; 	# 確認用出力
	print "\@years_ref : @years_ref \n"; 	# 確認用出力

	print "\n\@eachyear : @eachyear \n"; 	# 確認用出力
	print "\@var_eachyear : @var_eachyear \n"; 	# 確認用出力
	print "\@var_ref_eachyear : @var_ref_eachyear \n"; 	# 確認用出力

	# グラフに @eachyear, @var_eachyear, @var_ref_eachyear を渡す
	&graph(\@eachyear, \@var_eachyear, \@var_ref_eachyear, \@title_char); 	#リファレンス渡し

} 	# 地域でloop
} 	# シナリオでloop
} 	# 変数でloop


#=============
# Graph 処理
#=============
sub graph { 

	my ($labels, $dataset1, $dataset2, $title_char ) = @_; 	# 配列のリファレンスを変数で一旦受けて

	my @labels = @$labels; 	# デリファレンス
	my @dataset1 = @$dataset1; 	# デリファレンス
	my @dataset2 = @$dataset2; 	# デリファレンス
	my @title_char = @$title_char; 	# デリファレンス

	print "\n＜ここから Graphサブルーチン＞\n"; 	# 確認用出力
	print "\@labels : @labels \n"; 	# 確認用出力
	print "\@dataset1 : @dataset1 \n"; 	# 確認用出力
	print "\@dataset2 : @dataset2 \n"; 	# 確認用出力
	print "\@title_char : @title_char \n"; 	# 確認用出力

	my $MODEL	 = $title_char[0]; 	# 仮指定
	my $SCENARIO = $title_char[1]; 
	my $REGION	 = $title_char[2]; 
	my $VARIABLE = $title_char[3]; 
	my $UNIT	 = $title_char[4]; 

		# GD::Graph書式	
		my @data    = ( \@labels, \@dataset1, \@dataset2);
#		my $graph = GD::Graph::linespoints->new(400, 400);
		my $graph = GD::Graph::points->new(400, 400);

		$graph->set( 
			x_label           => 'Year',
			y_label           => "$VARIABLE ($UNIT)",
			title             => "$VARIABLE | $SCENARIO | $REGION",
			x_label_skip      => 20,  
		#	y_max_value       => 8,
			y_tick_number     => 10
		#	y_label_skip      => 10 
		) or die $graph->error;

		$graph->set_legend('Scenario', 'Reference');
#		$graph->set_legend_font('GD::gdTinyFont'); 	# 他フォントは 要GD::Text 

		my $gd = $graph->plot(\@data) or die $graph->error;

		foreach ($REGION, $SCENARIO, $VARIABLE) { 	# ファイル名に使う変数を指定
			s/\/_/ig;	# ファイル名エラー個別指定
			s/\?/_/ig;	# ファイル名エラー個別指定
			s/[\.\,\"\'\*]//ig;	# ファイル名の禁則文字は削除
			s/[\/]/_/ig;	# ファイル名の禁則文字の置換
			s/[\|]/_/ig;	# ファイル名の禁則文字の置換
		}

		open(IMG, ">../$result_derectory/($VARIABLE)\_$SCENARIO\_$REGION.gif") or die "$!";
		binmode IMG;
		print IMG $gd->gif;
		close IMG;

		print "($VARIABLE)\_$SCENARIO\_$REGION.gif Completed! \n"; 	# 確認用出力

} 	# graph 終了


#=============
# uniq 処理
#=============
sub uniq { 
	my (@array) = @_;
	my %appearance;
	my @unique = grep !$appearance{$_}++, @array; 	# @array をキーとするハッシュを評価し、初登場なら @unique に追加
	return @unique;
} 	# uniq 終了

#=============
# Close 処理
#=============
# close(STDOUT);

__END__
:endofperl

