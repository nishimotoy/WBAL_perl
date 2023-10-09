@rem = '  Indicator_both.pl 過去/将来の両方に対応する revised from Indicator_step_f.pl

@echo off

set INPUT=REF2
set OUTPUT=GRAPH2
rmdir /s /q %OUTPUT%
mkdir %OUTPUT%

set TYPE=PAST

mkdir %OUTPUT%\%TYPE%\GDP
perl %0 %INPUT% %OUTPUT%\%TYPE%\GDP %TYPE% GDP_Capita= "GDP_IEA" / "POP_IEA" >> %OUTPUT%\%TYPE%\GDP\log_GDP_Capita.txt
start %OUTPUT%\%TYPE%\GDP\log_GDP_Capita.txt

mkdir %OUTPUT%\%TYPE%\EI
perl %0 %INPUT% %OUTPUT%\%TYPE%\EI %TYPE% Energy_Intensity= "TES_Total" / "GDP_IEA" > %OUTPUT%\%TYPE%\EI\log_Energy_Intensity.txt
start %OUTPUT%\%TYPE%\EI\log_Energy_Intensity.txt

mkdir %OUTPUT%\%TYPE%\CI
perl %0 %INPUT% %OUTPUT%\%TYPE%\CI %TYPE% Carbon_Intensity= "CO2_fuel_Total" / "TES_Total" > %OUTPUT%\%TYPE%\CI\log_Carbon_Intensity.txt
start %OUTPUT%\%TYPE%\CI\log_Carbon_Intensity.txt

for %%s in (Total Ind Tra Res Com AgFo) do (
	mkdir %OUTPUT%\%TYPE%\ER_%%s
	perl %0 %INPUT% %OUTPUT%\%TYPE%\ER_%%s %TYPE% Electricity_Rate_%%s= "TFC_Elec_%%s" / "TFC_Total_%%s" > %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt
	start %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt
)
PAUSE

set TYPE=FUTURE

mkdir %OUTPUT%\%TYPE%\GDP
perl %0 %INPUT% %OUTPUT%\%TYPE%\GDP %TYPE% GDP_Capita= "GDP^|MER" / "Population" >> %OUTPUT%\%TYPE%\GDP\log_GDP_Capita.txt
start %OUTPUT%\%TYPE%\GDP\log_GDP_Capita.txt

mkdir %OUTPUT%\%TYPE%\EI
perl %0 %INPUT% %OUTPUT%\%TYPE%\EI %TYPE% Energy_Intensity= "Primary Energy" / "GDP^|MER" > %OUTPUT%\%TYPE%\EI\log_Energy_Intensity.txt
start %OUTPUT%\%TYPE%\EI\log_Energy_Intensity.txt

mkdir %OUTPUT%\%TYPE%\CI
perl %0 %INPUT% %OUTPUT%\%TYPE%\CI %TYPE% Carbon_Intensity= "Emissions^|CO2^|Energy" / "Primary Energy" > %OUTPUT%\%TYPE%\CI\log_Carbon_Intensity_Total.txt
start %OUTPUT%\%TYPE%\CI\log_Carbon_Intensity_Total.txt

for %%s in (Total) do (
	mkdir %OUTPUT%\%TYPE%\ER_%%s
	perl %0 %INPUT% %OUTPUT%\%TYPE%\ER_%%s %TYPE% Electricity_Rate_%%s= "Final Energy^|Electricity" / "Final Energy" > %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt
	start %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt
)

for %%s in (Industry Transportation Residential Commercial) do (
	mkdir %OUTPUT%\%TYPE%\ER_%%s
	perl %0 %INPUT% %OUTPUT%\%TYPE%\ER_%%s %TYPE% Electricity_Rate_%%s= "Final Energy^|%%s^|Electricity" / "Final Energy^|%%s" > %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt
	start %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt
)
PAUSE

goto endofperl
@rem ' ;

# batコマンド 仮置き
# exit /B 0

#	perl %0 %INPUT% %OUTPUT%\%TYPE%\EI %FILE% Energy_Intensity= "TES_Total" / "GDP_IEA" > %OUTPUT%\%TYPE%\EI\log_Energy_Intensity.txt
#	perl %0 %INPUT% %OUTPUT%\%TYPE%\CI %FILE% Carbon_Intensity= "CO2_fuel_Total" / "TES_Total" > %OUTPUT%\%TYPE%\CI\log_Carbon_Intensity_Total.txt
# 	for %%s in (Total Ind Tra Res Com) do ( 
#	perl %0 %INPUT% %OUTPUT%\%TYPE%\ER_%%s %FILE% Electricity_Rate_%%s= "TFC_Elec_%%s" / "TFC_Total_%%s" > %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt

#	perl %0 %INPUT% %OUTPUT%\%TYPE%\EI Energy_Intensity= "Primary Energy" / "GDP^|MER" > %OUTPUT%\%TYPE%\EI\log_Energy_Intensity.txt
#	perl %0 %INPUT% %OUTPUT%\%TYPE%\CI Carbon_Intensity= "Emissions^|CO2^|Energy" / "Primary Energy" > %OUTPUT%\%TYPE%\CI\log_Carbon_Intensity_Total.txt
#	perl %0 %INPUT% %OUTPUT%\%TYPE%\ER_%%s Electricity_Rate_%%s= "Final Energy^|Electricity" / "Final Energy" > %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt
#	perl %0 %INPUT% %OUTPUT%\%TYPE%\ER_%%s Electricity_Rate_%%s= "Final Energy^|%%s^|Electricity" / "Final Energy^|%%s" > %OUTPUT%\%TYPE%\ER_%%s\log_Electricity_Rate_%%s.txt

#! /usr/local/bin/perl
# Indicator_step.pl	2変数を指定して指標を算出、年間隔を指定

#==========
# 構成
#==========
#     
#     +-- here / Indicator_step.pl  	このファイル、計算の本体
#			|    Test.bat				入出力指定コマンド
#			|
#			+-- REF2 	参照データ用フォルダ
#			|			IAMCTemplate_ref.csv	入力ファイル	$file_input
#			|									
#			+-- GRAPH3 	出力用フォルダ
#						log.txt					エラー等の確認ファイル
#						(変数名)_シナリオ名_地域名.gif
#						(指標名)_シナリオ名_地域名.gif
#						(Change_Rate_指標名)_シナリオ名_地域名.gif
#						IAMCTemplate_out.csv	出力ファイル	$file_output

#=============
# フロー
#=============

# (1) IAMCTemplate_ref.csv読込　＞ タイトル行取得@years ＞ 条件マッチ($VARIABLE/$SCENARIO)＞ データ行取得@var
# (2) 取得した @years, @var を各年に変換 ＞ @eachyear, @var_eachyear
# (2-2) 指定した間隔の @var_step(@year_step) に変換する。基準年($BaseYear)の前後の指定間隔($StepYear) ＞ @var上書き
# (3) 指標、その変化率の算出＞ @indicator, @indicator_change_rate
# (4) 指標の数値ファイル(csv)の出力	＞ $file_output
# (5) グラフファイルの出力＞ @var_eachyear, @indicator, @indicator_change_rate
# (6) 指標のグラフファイルの出力＞ @indicator
# (7) 変化率のグラフファイルの出力＞ @indicator_change_rate

#=============
# 設定
#=============

use strict;
use warnings;
use GD::Graph::linespoints;
use GD::Graph::points;
use File::Path;

my $reference_derectory = $ARGV[0];	# "REF2";	# 参照データの場所、CSV前提（そのうち形式SWITCHにする）
my $result_derectory = $ARGV[1];	# "GRAPH3\TYPE\Indicator";	# 結果データの場所、CSV前提（同上）

# フォーマット指定
my @title_line = qw( MODEL SCENARIO REGION VARIABLE UNIT );	# yearの前までの配列
my @regions = qw( XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF );	# 地域の配列　qw( USA XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF ASIA2 World );
my $unit;

my $type = $ARGV[2];	# past or future

my $file_input = "IAMCTemplate.csv"; 	# 元データファイル＠将来 "IAMCTemplate_ref.csv"; ＠過去
if ($type eq "PAST") { $file_input = "IAMCTemplate_ref.csv"; }

my $file_output = "IAMCTemplate_i_future.csv"; 	# 出力ファイル
if ($type eq "PAST") { $file_output = "IAMCTemplate_i_past.csv"; }

my @scenarios = qw( Baseline 2C ); 	# シナリオの配列 qw( Reference );  qw( Baseline 1.5C 2C 2.5C WB2C );
if ($type eq "PAST") { @scenarios = qw( Reference ); }

my @variables_for_Indicator = @ARGV[3..6];
# [0]指標名 [1]変数1 [2]演算子 [3]変数2 の順番で指定する	
# 変数1[1]と変数2[3]の位置を変えた場合はコード変更が必要、指標名[0]と演算子[2]はタイトル表示に使用

@variables_for_Indicator = map { $_ =~ s/\^//ig; $_ } @variables_for_Indicator; 	# batのエスケープ文字の削除

my $BaseYear = 2010;	# 基準年　指標変化率 (@indicator_change_rate) 他で使用
my $StepYear = 5;	# ステップ年　変化率を計測する単位

#=============
# 準備
#=============
# rmtree($result_derectory);
# mkdir $result_derectory or die "$result_derectory を作成することができません。 : $!";
# open(STDOUT,">$result_derectory/log.txt");

my ($line, @line);
my (@years, @var, @title_char);	# グラフに渡すデータ
my ($file, $region, $variable, $variable_no, $scenario, $scenario_no ) = undef; 	# loop中で使う変数
my $title;	# 指標名
my (%indicator, %indicator_change_rate, %indicator_change_rate_baseYear, %indicator_change_rate_priorYear ) = (); 	# 指標と変化率のハッシュの初期化

print "\@variables_for_Indicator : @variables_for_Indicator \n"; 	# 確認用出力
print "\$type : $type \t \$file_input : $file_input \t \$file_output : $file_output \t \@scenarios : @scenarios \n"; 	# 確認用出力

#=============
# 1条件の処理		# 変数、シナリオ、地域のセット
#=============

chdir $reference_derectory;
foreach $scenario(@scenarios) { 	# シナリオでloop

	foreach $region(@regions) { 	# 地域でloop

		my (@var1, @var2, @indicator, @indicator_change_rate ) = undef; 	# 指標とその算出に用いる変数の初期化
		my (@indicator_change_rate_baseYear, @indicator_change_rate_priorYear ) = undef; 	# 指標変化率の正規化用
		my ($unit_var1, $unit_var2 ) = undef; 	# 指標用の単位

		foreach $variable($variables_for_Indicator[1],$variables_for_Indicator[3]) { 	# 変数でloop

			print "\n\n【START】 \t variable : $variable \t scenario : $scenario \t region : $region \n"; 	# 確認用出力

			foreach $file($file_input) { 	# ファイルでloop

				(@years, @var, @title_char) = ();	# 初期化
				print "\$file : $file \n"; 	# 確認用出力

				open(IN,"$file") or die "Can't open: $file: $!";	# 指定形式の出力
				$line = <IN>;	# 先頭行の読込　年タイトル行
				print "\$line : $line \n"; 	# 確認用出力
				$line =~ s/\"(\b.*?\b)\"/$1/ig;	# 最小マッチ　 "*", パターン
				chomp ($line);
				@line = split(/\,/, $line);	# とりあえずカンマで区切る
				print "\@line : @line \n"; 	# 確認用出力
				@years = @line[$#title_line+1..$#line]; 	# タイトル行から年を取得
				print "\n\$file : $file \n \@years : @years \n \@line : @line \n"; 	# 確認用出力

				while (<IN>) {	#データ行の処理開始
					s/\"(\b.*?\b)\"/$1/ig;	# 最小マッチ　 "*", パターン
					chomp;
					@line = split(/\,/);	# とりあえずカンマで区切る
#					unless ( $line[1] ) { next; }
					if ( ($line[1] eq $scenario)&&($line[2] eq $region)&&($line[3] eq $variable) ) { 
						# VARIABLE SCENARIO region が一致したら
						@var = @line[$#title_line+1..$#line]; 	# 年に相当する値を取得
						@title_char = @line[0..$#title_line]; 	# ヒットした行のタイトルを取得
						last; 	# ヒットしたらlast文
					}
				} 	# #データ行の処理ここまで
				close(IN);
			} 	# ファイルでloop

			print "\n＜読込終了＞ \t \$region : $region \t \$variable : $variable \t \$scenario : $scenario \n"; 	# 確認用出力
			print "\@years : @years \n"; 	# 確認用出力
			print "\@var : @var \n"; 	# 確認用出力

			# @var 処理 ＜ここから＞
			# @var が正常に入ってない場合は、以降の処理をSKIP（@variables_for_Indicator にダミーを入れた際に導入）
			unless ( @var ) { print "SKIPPED \n"; next; } 	

			# eachyear処理（@years, @var を渡して @eachyear, @var_eachyear を受け取る）
			my ($eachyearRef, $var_eachyearRef ) = &eachyear(\@years, \@var);	# リファレンス渡し、リファレンス受取
			my @eachyear = @$eachyearRef; 	# デリファレンス
			my @var_eachyear = @$var_eachyearRef; 	# デリファレンス

			# グラフ渡し用配列の確認
#			print "\n＜&eachyear後＞\n"; 	# 確認用出力
#			print "\n\@eachyear : @eachyear \n"; 	# 確認用出力
#			print "\@var_eachyear : @var_eachyear \n"; 	# 確認用出力

			# グラフに @eachyear, @var_eachyear を渡す
			&graph(\@eachyear, \@var_eachyear, \@title_char); 	#リファレンス渡し
			# @var 処理 ＜ここまで＞

			if (1) {	# @var_step 処理 ＜ここから＞
				# @eachyear, @var_eachyear のハッシュ化
				my %hash_eachyear = ();
				@hash_eachyear{@eachyear} = @var_eachyear; #ハッシュのスライス
#				print "\%hash_eachyear \n"; 	# 確認用出力
#				for my $key (sort keys %hash_eachyear){ print "key: $key value: $hash_eachyear{$key}\n"; }
#				print "\n"; 	# 確認用出力

				# 基準年($BaseYear)を中心に、一定間隔($StepYear)の配列を作成
				my @year_step = ();
				for ( my $t=$BaseYear ; $t<=$eachyear[$#eachyear] ; $t=$t+$StepYear ) { 
					push (@year_step, $t);
				}
				for ( my $t=$BaseYear ; $t>=$eachyear[0] ; $t=$t-$StepYear ) { 
					push (@year_step, $t);
				}
				@year_step = uniq(sort(@year_step)); 	# 重複, SKIP対策（上のfor文は、重複前提）

				my @var_step = ();
				for my $key (@year_step){ 
					push (@var_step, $hash_eachyear{$key}); 
				}
				print "\@year_step : @year_step \n"; 	# 確認用出力
				print "\@var_step : @var_step \n"; 	# 確認用出力

				# @years, @varを置換
				@years = @year_step;
				@var = @var_step;
				&graph(\@years, \@var, \@title_char); 	#グラフ出力
			}	# @var_step 処理 ＜ここまで＞


			# @indicator処理＜ここから＞
			# 準備（基準年の値）
			my $BaseYear_num = "none"; 	# 基準年値の配列番号、@years の中で 基準年が何番目か
			while ( my ($i,$j) = each @years ) {
				$BaseYear_num = $i if ($j==$BaseYear); 
			}
			if ( $BaseYear_num eq "none" ) { 	# 初期値のままなら、エラー出力
				print "【基準年($BaseYear)が、入力データに含まれていません】\$BaseYear_num : $BaseYear_num \n"; 
			} else {
				print "【基準年値は $BaseYear_num 番目の要素です】\n" ;
			}

			# @indicator算出の要素マッチ（分子、分母）
			if ( $variable eq $variables_for_Indicator[1] ) { 	# 分子に指定した変数である場合 [1]指定 
				@var1 = @var; 	# 分子
				$unit_var1 = $title_char[4]; 	# 単位
				print "\@var1 : @var1 \n"; 	# 確認用出力
				print "\$unit_var1 : $unit_var1 \n"; 	# 確認用出力
			} elsif ( $variable eq $variables_for_Indicator[3] ) { 	# 分母に指定した変数である場合 [3]指定 
				@var2 = @var; 	# 分母
				$unit_var2 = $title_char[4]; 	# 単位
				print "\@var2 : @var2 \n"; 	# 確認用出力
				print "\$unit_var2 : $unit_var2 \n"; 	# 確認用出力
			} 

			# @indicator算出
			if ( (@var1!=0)&&(@var2!=0) ) { 	# 両変数が揃った時のみ
				print "【指標】\@years \t \@var1 \t \@var2 \t \@indicator \t \@indicator_change_rate \n"; 	# 確認用出力
				foreach (0..$#var1) { 
					if ( ($var1[$_])&&($var2[$_]) ) {	# 両変数に共に値がある年に
						$indicator[$_] = $var1[$_] / $var2[$_]; 	# 指標の算出
						$indicator{$years[$_]}{$region} = $indicator[$_]; 	# 指標のハッシュ化 ＞ csv出力用
						if ($indicator[$_-1]) { 	# 前年に指標がある場合
							$indicator_change_rate[$_] = ($indicator[$_]-$indicator[$_-1])/($years[$_]-$years[$_-1]); 	# 指標の変化率
							# $indicator_change_rate{$years[$_]}{$region} = $indicator_change_rate[$_]; 	# 指標の変化率のハッシュ化
						} else {
							$indicator_change_rate[$_] = undef; 	# 前年の指標が欠けている場合はundef
							# $indicator_change_rate{$years[$_]}{$region} = undef; 	# ハッシュも同様に undef
						}

					} else {
						$indicator[$_] = undef; 	# いずれかの値が欠けている年の指標はundef
						# $indicator_change_rate[$_] = undef; 	# いずれかの値が欠けている年の指標はundef
					}
				$indicator_change_rate{$years[$_]}{$region} = $indicator_change_rate[$_]; 	# 指標の変化率のハッシュ化
				print "\t $years[$_] \t $var1[$_] \t $var2[$_] \t $indicator[$_] \t $indicator_change_rate[$_] \n"; 	# 確認用出力
				}
				print "\n\n"; 	# 確認用出力

				# @indicator_change_rate の規格化
				my $val_baseYear = $indicator[$BaseYear_num];
				unless ( $val_baseYear ) { print "【基準年値が、存在しません】\n"; }

=pod # 9/21
				foreach (0..$#years) {
					if ( $val_baseYear ) { # 基準年の値が存在する場合
						$indicator_change_rate_baseYear[$_] = $indicator_change_rate[$_] / $val_baseYear;
						# @indicator_change_rate_baseYear = map { $_ /  $val_baseYear } @indicator_change_rate; 	# 9/15 変更
						$indicator_change_rate_baseYear{$years[$_]}{$region} = $indicator_change_rate_baseYear[$_]; 	# 出力用ハッシュ
					} else {
						$indicator_change_rate_baseYear[$_] = undef; 
						# @indicator_change_rate_baseYear = map { $_ = undef; $_ } @indicator_change_rate; 	# 9/15 変更
					}
					if ($indicator[$_-1]) { 	# 前期(t-1)の値が存在する場合
						$indicator_change_rate_priorYear[$_] = $indicator_change_rate[$_] / $indicator[$_-1];
					} else {
						$indicator_change_rate_priorYear[$_] = undef; 
					}
				}
=cut # 9/21

				foreach (0..$#years) {
					if ( $val_baseYear ) { # 基準年の値が存在する場合
						$indicator_change_rate_baseYear[$_] = $indicator_change_rate[$_] / $val_baseYear;
						# @indicator_change_rate_baseYear = map { $_ /  $val_baseYear } @indicator_change_rate; 	# 9/15 変更
						$indicator_change_rate_baseYear{$years[$_]}{$region} = $indicator_change_rate_baseYear[$_]; 	# 出力用ハッシュ
					} else {
						$indicator_change_rate_baseYear[$_] = undef; 
						# @indicator_change_rate_baseYear = map { $_ = undef; $_ } @indicator_change_rate; 	# 9/15 変更
					}
					if ($indicator[$_-1]) { 	# 前期(t-1)の値が存在する場合
						$indicator_change_rate_priorYear[$_] = $indicator_change_rate[$_] / $indicator[$_-1];
					} else {
						$indicator_change_rate_priorYear[$_] = undef; 
					}
				}

				print "\@indicator_change_rate : @indicator_change_rate \n"; 	# 確認用出力
				print "\@indicator_change_rate_baseYear : @indicator_change_rate_baseYear \n"; 	# 確認用出力
				print "\@indicator_change_rate_priorYear : @indicator_change_rate_priorYear \n"; 	# 確認用出力

				# @indicator_change_rateのハッシュ化


				# グラフに @indicator 表示用のデータを渡す
				$title = $variables_for_Indicator[0];	# 指標名
				$title =~ s/\=//ig;	# 置換処理 = を削除
				print "\$title : $title\n"; 	# 確認用出力
				$title_char[3] = $title;	# グラフに表示する変数名
				$title_char[4] = $unit_var1.$variables_for_Indicator[2].$unit_var2;	# 指標の単位　[2]<-符号の位置を指定
				print "\$title_char[4] : $title_char[4]\n"; 	# 確認用出力
				$title_char[5] = join(' ', @variables_for_Indicator);	# グラフに表示する
				&graph(\@years, \@indicator, \@title_char); 	# graph @indicator

				# グラフに @indicator_change_rate 表示用のデータを渡す
				$title_char[3] = "ChangeRate_".$title;	# グラフに表示する変数名	#後で単位も処理すること
				&graph(\@years, \@indicator_change_rate, \@title_char); 	# graph 

				# グラフに @indicator_change_rate 表示用のデータを渡す
				$title_char[3] = "ChangeRate(b)_".$title;	# グラフに表示する変数名	#後で単位も処理すること
				&graph(\@years, \@indicator_change_rate_baseYear, \@title_char); 	# graph 

				# グラフに @indicator_change_rate 表示用のデータを渡す
				$title_char[3] = "ChangeRate(t)_".$title;	# グラフに表示する変数名	#後で単位も処理すること
				&graph(\@years, \@indicator_change_rate_priorYear, \@title_char); 	# graph 

			} 
			# @indicator処理＜ここまで＞

		} 	# 変数でloop
	} 	# 地域でloop


	#==========================
	# 「IAMCTemplate」形式ファイルの出力（csv）
	#==========================

	open (OUT, ">>../$result_derectory/../../$file_output") or die "Can't open: $file_output: $!";	# 指定形式の出力
	print "【IAMCTemplate 形式ファイルの出力】\n"; 	# 確認用出力

	my ($title_line, $year);
	foreach $title_line(@title_line) { print OUT "\"$title_line\","; }	# タイトル行はファイル毎に出力している
	foreach $year(@years) { print OUT "\"$year\","; }	# ∵ファイル間の year の一致を前提としない
	print OUT "\n"; 

	$title_char[3] = $title;	# 指標名
	foreach $region(@regions) { 

		$title_char[2] = $region;	# 地域
		foreach (0..4) { print OUT "\"$title_char[$_]\","; }		# 文字列データの出力

		foreach $year(@years) { 
			print OUT "$indicator{$year}{$region},"; 	# 指標データの出力
			print "\%indicator {$year} {$region} : $indicator{$year}{$region}\n"; 	# 確認用出力
		}
		print OUT "\n"; 
	} 	# loop by $region 


	$title_char[3] = "ChangeRate_".$title;	# 指標名
	$title_char[4] = $title_char[4]."/y"; 	# 単位
	foreach $region(@regions) { 

		$title_char[2] = $region;	# 地域
		foreach (0..4) { print OUT "\"$title_char[$_]\","; }		# 文字列データの出力

		foreach $year(@years) { 
			print OUT "$indicator_change_rate_baseYear{$year}{$region},";  	# 変化率データの出力、基準年
			print "\$indicator_change_rate_baseYear {$year} {$region} : $indicator_change_rate_baseYear{$year}{$region}\n"; 
		}
		print OUT "\n"; 

	} 	# loop by $region 
	print OUT "\n"; 
	close(OUT);
	# 「IAMCTemplate」形式ファイルの出力（csv）＜ここまで＞
}
# シナリオでloop
chdir "./..";


#=============
# Graph 処理
#=============
sub graph { 

	my ($labels, $dataset1, $title_char ) = @_; 	# 配列のリファレンスを変数で一旦受けて
#	my ($labels, $dataset1, $dataset2, $title_char ) = @_; 	# 2変数のとき

	my @labels = @$labels; 	# デリファレンス
	my @dataset1 = @$dataset1; 	# デリファレンス
#	my @dataset2 = @$dataset2; 	# デリファレンス 	# 2変数のとき
	my @title_char = @$title_char; 	# デリファレンス

	print "\n【Graph】\n"; 	# 確認用出力
#	print "\@labels : @labels \n"; 	# 確認用出力
#	print "\@dataset1 : @dataset1 \n"; 	# 確認用出力
#	print "\@dataset2 : @dataset2 \n"; 	# 確認用出力 	# 2変数のとき
#	print "\@title_char : @title_char \n"; 	# 確認用出力

	my $MODEL	 = $title_char[0]; 	# 仮指定
	my $SCENARIO = $title_char[1]; 
	my $REGION	 = $title_char[2]; 
	my $VARIABLE = $title_char[3]; 
	my $UNIT	 = $title_char[4]; 
	my $LEGEND	 = $title_char[5]; 

		# GD::Graph書式	
		my @data    = ( \@labels, \@dataset1 );
#		my @data    = ( \@labels, \@dataset1, \@dataset2); 	# 2変数のとき
#		my $graph = GD::Graph::linespoints->new(400, 400);
		my $graph = GD::Graph::points->new(400, 400);

		$graph->set( 
			x_label           => 'Year',
			y_label           => "$VARIABLE ($UNIT)",
			title             => "$VARIABLE | $SCENARIO | $REGION",
		#	x_label_skip      => 20, 	# 5年間隔にした際に導入
		#	y_max_value       => 8, 
			y_tick_number     => 10
		#	y_label_skip      => 10 
		) or die $graph->error;

		$graph->set( x_label_skip => 20 ) or die $graph->error if ( $StepYear < 5 ); 	# Xラベルの間引き


		$graph->set_legend("$LEGEND") if ( $LEGEND ); 	# 1変数のとき
#		$graph->set_legend('Scenario', 'Reference'); 	# 2変数のとき
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

		print "($VARIABLE)\_$SCENARIO\_$REGION.gif Completed! \n\n"; 	# 確認用出力

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
# eachyear （数年置きや不規則な間隔の数列を1年間隔に変更する）
#=============
sub eachyear { 

	my ($yearsRef, $varRef ) = @_; 	# 配列のリファレンスを変数で一旦受けて

	my @years = @$yearsRef; 	# デリファレンス
	my @var = @$varRef; 	# デリファレンス

	# グラフ用ハッシュ（年をキーとして値を返す）の作成
	my %varHash = map { $years[$_] => $var[$_] } (0..$#years); # 変換用ハッシュと年キー、$varhash{$year}
#	foreach (0..$#years) { print "(2)\t\$varHash{$years[$_]} : $varHash{$years[$_]} \n"; }

	my @years_sort = uniq(sort(@years)); 	# 重複, SKIP対策
	my $years_min = $years_sort[0]; 	# 
	my $years_max = $years_sort[$#years_sort]; 	# 

	my (@eachyear, @var_eachyear, $t, $dt, $pre_year, $post_year) = undef;
	for ( $t=0; $t<=$years_max-$years_min ; $t++ ) { 
		$eachyear[$t] = $years_min + $t;
		if ( $varHash{$eachyear[$t]} ) { 
			$var_eachyear[$t] = $varHash{$eachyear[$t]}; 
		} else {
			$var_eachyear[$t] = undef; 	# 値のない年＝未定義 とする場合
		}
#		print "\$t:$t \t \$eachyear[$t]:$eachyear[$t] \t \$var_eachyear[$t]:$var_eachyear[$t]  \n"; 	# 確認用出力 
	}

	# 補間配列	# （残る課題 @var_eachyear=0 の場合）	# 未完
	foreach $t(0..$#eachyear) { 	# 配列番号によるloop（1から始めるのは、0の場合は前期の値が無いため）
		$pre_year = $eachyear[$t] if ($var_eachyear[$t]); 
		if ( $var_eachyear[$t] eq undef ) {
			$post_year = undef; 
			foreach $dt($t..$#eachyear) { 	# 配列番号によるloop
				if ( $var_eachyear[$dt] ) { 
					$post_year = $eachyear[$dt]; 
#					print "\$t:$t \t \$dt:$dt \t \$pre_year:$pre_year \t \$post_year:$post_year \n"; 	# 確認用出力
					last; 
				}
			}

		}
	}
	# 補間配列	# 未完
	# 後回し＞ ( $var_eachyear[$t] == undef ) の場合の補間処理

	my @eachyearReturn = (\@eachyear, \@var_eachyear); 	# 2配列のリファレンスを返す
	return @eachyearReturn;
} 	# eachyear 終了

#=============
# Close 処理
#=============
# close(STDOUT);

__END__
:endofperl


:endofperl

