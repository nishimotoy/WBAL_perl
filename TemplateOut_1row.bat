@rem = '  TemplateOut_1row.pl 一行データ(国データ)を IAMCTemplate出力

set INPUT=REF
set OUTPUT=GRAPH6
rmdir /s /q %OUTPUT%
mkdir %OUTPUT%

perl %0 %INPUT% %OUTPUT% > %OUTPUT%\log.txt
start %OUTPUT%\log.txt
PAUSE

goto endofperl
@rem ' ;

#! /usr/local/bin/perl
# TemplateOut_1row.pl		一行データ(国データ)を IAMCTemplate出力


#==========
# 構成
#==========
#     
#     +-- here / TemplateOut_1row.pl  	このファイル、計算の本体
#			|
#			+-- REF 	参照データ用フォルダ
#			|			(項目名).csv			個別項目のデータファイル、「年×国名」形式のcsvファイル
#			|									IEAブラウザの出力ファイルを無加工で使う
#			|									年のタイトル行が1行目
#			|			unit.txt				(項目名)－単位の定義ファイル、タブ区切テキスト
#			+-- GRAPH 	出力用フォルダ
#				|		log.txt					エラー等の確認ファイル
#				+-- (項目名1) 					項目毎のグラフ収納フォルダ
#				|		(項目名)_地域名1.gif
#				|		(項目名)_地域名2.gif
#				|		(項目名)_地域名3.gif
#				+-- (項目名2) 					項目毎のグラフ収納フォルダ
#				|		(項目名)_地域名1.gif
#				|		(項目名)_地域名2.gif
#				|		(項目名)_地域名3.gif
#				+-- (項目名n) 					項目毎のグラフ収納フォルダ

#=============
# フロー
#=============

# (1) タイトル行（年）読込
# (2) データ行（1行/1地域）読込
# (3) グラフファイルの出力
# (4) (2)-(3)を地域数だけ繰り返す


#=============
# 設定
#=============

use strict;
use warnings;
use GD::Graph::linespoints;
use GD::Graph::points;
use File::Path;

my $reference_derectory = "$ARGV[0]";	# "REF"; # 参照データの場所、CSV前提（そのうち形式SWITCHにする）
my $result_derectory = "$ARGV[1]";	# "GRAPH1";	# 結果データの場所、CSV前提（同上）
my $unit_filename = "unit.txt";	# 項目名と単位のファイル

my $file_output = "IAMCTemplate_out_countries.csv"; 	# 出力ファイル
my @title_line = qw( MODEL SCENARIO REGION VARIABLE UNIT );	# yearの前までの配列
my @title_char = @title_line;	# グラフに渡すデータ

my $code_filename = "CC.txt";	# コード定義ファイル、タブ区切テキスト
my $target_code_no = 1;	# 処理対象の列番号 ＠コード定義ファイル（A列=0, B列=1）
my $add_code_no = 5;	# 付与対象の列番号 ＠コード定義ファイル

#=============
# 準備
#=============

# rmtree($result_derectory);
# mkdir $result_derectory or die "$result_derectory を作成することができません。 : $!";
# open(STDOUT,">$result_derectory/log.txt");

open (OUT, ">$result_derectory/$file_output") or die "Can't open: $file_output: $!";	# テンプレート出力
chdir $reference_derectory;

#=============
# コード定義ハッシュの作成
#=============

open (IN, "$code_filename") or die "Can't open: $code_filename: $!";

my $line = <IN>;	# 先頭行＜読み込んで放置
# chomp ($line);
# my @title = split(/\t/, $line);
# print "\@title : \t@title\t END \n\n";	# 確認用出力


my %code_match_hash; 	# 国=>地域 コードマッチ用のハッシュ生成
while  (<IN>)  {
	chomp;
	my @for_hash = split(/\t/);	# タブで分割
	# 列番号による配列 => それをキーとするハッシュ
	$code_match_hash{$for_hash[$target_code_no]} = $for_hash[$add_code_no];	
	print "\%code_match_hash : $for_hash[$target_code_no] -> $code_match_hash{$for_hash[$target_code_no]}\n";	# 確認用出力
}
close(IN);
print "\n";	# 確認用出力

#=============
# コード定義ハッシュのキーリストを取得する
#=============

my @regions_aggregated = uniq(sort(values(%code_match_hash)));
print "\@regions_aggregated : @regions_aggregated \n"; 	# 確認用出力

if ( $regions_aggregated[0] eq '' ) { 	# 空データがあったら削除
							# sort＞uniq後なので[0]番目の要素だけをチェックしている
	print "shift処理前  \$regions_aggregated[0] : $regions_aggregated[0] \t \$regions_aggregated[1] : $regions_aggregated[1] \n"; 	# 確認用出力
	shift(@regions_aggregated);	# $years[0] は国コードが入る前提なので
	print "shift処理後  \$regions_aggregated[0] : $regions_aggregated[0] \t \$regions_aggregated[1] : $regions_aggregated[1] \n"; 	# 確認用出力
}


#=============
# 単位ハッシュの作成
#=============

open (IN, "$unit_filename") or die "Can't open: $unit_filename: $!";

my %item_unit_hash; 	# 項目名=>単位 マッチ用のハッシュ生成
while  (<IN>)  {
	chomp;
	s/(.csv)//ig;	# 確認用出力
	s/(.txt)//ig;	# 確認用出力

	my @for_hash = split(/\t/);	# タブで分割
	# 列番号による配列 => それをキーとするハッシュ
	$item_unit_hash{$for_hash[0]} = $for_hash[1];	
	print "\%item_unit_hash : $item_unit_hash{$for_hash[0]} \t $for_hash[0] -> $for_hash[1] \n";	# 確認用出力
}
close(IN);
print "\n";	# 確認用出力


#=============
# タイトル行の読込
#=============

my $file; 
my @years;
my ($year, $region);
# my %yeardata;	# 年×地域コードの値を代入するためのハッシュ生成

while ( $file = glob("*.csv") ) { 	 # 1ファイルの処理＜ここから＞

	open(IN,"$file");
	print "\n\n処理開始　\$file : $file\n"; 	# 確認用出力
	$file =~ s/\.csv//;
	my $unit = "$item_unit_hash{$file}";

	mkdir "../$result_derectory/$file" or die "$file フォルダを作成することができません。 : $!";

	# CSVファイルの先頭行から年の定義を取得

	my $line = <IN>;	# 先頭行の読込 「年×国」形式のファイル　年タイトル行
	chomp ($line);

	@years = split(/\,/, $line);
	shift(@years);	# $years[0] の列は、国コードが入る前提なので

# タイトル行の読込 ＜ここまで＞

#=============
# タイトル行の出力（初回のみ）
#=============

	print "＜「IAMCTemplate」形式ファイルの出力：タイトル行＞\n"; 	# 確認用出力

	my ($title_line, $year);
	foreach $title_line(@title_line) { print OUT "\"$title_line\","; }	# タイトル行はファイル毎に出力している
	foreach $year(@years) { print OUT "\"$year\","; }	# ∵ファイル間の year の一致を前提としない
	print OUT "\n"; 

# タイトル行の出力 ＜ここまで＞


#=============
# データ行の読込（1行1国）
#=============

	# データファイルの初期化
	($year, $region) = undef;

	while (<IN>) {	#データ行の処理開始

		if ( /^COUNTRY/ ) { next; }	# 余計な行の場合はSKIP

		chomp;
		my @line = split(/\,/);	# とりあえずカンマで区切る
		@line = csv(@line);	# CSVファイルの "セル内カンマ" 処理

		$region = $line[0];		# 先頭データ $line[0] は「国名」なので

		shift(@line);	# @line は @years に対応しているので

#		print "\n\$region : $region \n"; 	# 確認用出力
#		print "\@line : @line \n"; 	# 確認用出力

		my $sum_region = undef;	
		$sum_region = $code_match_hash{$region}; 	# 属する地域コード
		print "\$sum_region : $sum_region\t@line \n"; 		# 定義済・集計対象の地域についてはOUT1にリストを出力
		unless ($sum_region) { next; }		# 属する地域コードが無い場合は次の行へ


	#==========================
	# データ行の出力（1行ずつ処理）
	#==========================

	print "＜「IAMCTemplate」形式ファイルの出力：データ行＞\n"; 	# 確認用出力

	my ($title_line, $year);

	$title_char[3] = $file;	# 指標名
	$title_char[2] = $region;	# 地域
	foreach (0..4) { print OUT "\"$title_char[$_]\","; }		# 文字列データの出力

	foreach (0..$#years) { 
		print OUT $line[$_];	# データの出力
		print OUT ","; 	# 区切り文字の出力
#		print OUT "$indicator{$year},"; 	# 指標データの出力
#		print "\%indicator {$year} {$region} : $indicator{$year}\n"; 	# 確認用出力
	}
	print OUT "\n"; 


#	$title_char[3] = "ChangeRate_".$title;	# 指標名
#	$title_char[4] = $title_char[4]."/y"; 	# 単位
#	foreach $region(@regions) {  変化率の出力
#	} 	# loop by $region 
#	print OUT "\n"; 

	# 「IAMCTemplate」形式ファイルの出力（csv）＜ここまで＞

		#===============
		# グラフの作成
		#===============

		my @labels  = @years;
		my @dataset = @line;

		my @data    = ( \@labels, \@dataset);

		my $graph = GD::Graph::linespoints->new(400, 400);

		$graph->set( 
			x_label           => 'Year',
			y_label           => "$unit",
			title             => "$file | $region",
			x_label_skip      => 10,  
		#	y_max_value       => 8,
			y_tick_number     => 10,
		#	y_label_skip      => 10 
		) or die $graph->error;


		print "\$region : $region \n"; 	# 確認用出力
#		print "\@labels : @labels \n"; 	# 確認用出力
		print "\@dataset : @dataset \n"; 	# 確認用出力

		my $gd = $graph->plot(\@data) or die $graph->error;


		$region =~ s/Cura軋o/Curacao/ig;	# ファイル名エラー個別指定
		$region =~ s/Ce/Cote/ig;	# ファイル名エラー個別指定
		$region =~ s/C?te/Cote/ig;	# ファイル名エラー個別指定
		$region =~ s/R?union/Reunion/ig;	# ファイル名エラー個別指定

		$region =~ s/(Memo: )//ig;	# ファイル名の禁則文字は削除
		$region =~ s/(Memo\*: )//ig;	# ファイル名の禁則文字は削除
		$region =~ s/[\.\,\"\'\*]//ig;	# ファイル名の禁則文字は削除
		$region =~ s/[\/]/_/ig;	# ファイル名の禁則文字は削除

		print "3 : $region \n"; 	# 確認用出力


		open(IMG, ">../$result_derectory/$file/($file)\_$region.gif") or die "$!";
		binmode IMG;
		print IMG $gd->gif;
		close IMG;

		print "\($file)\_$region.gif Completed! \n"; 	# 確認用出力


	}			# データ行毎の処理終了

	print OUT "\n"; 
}	# 1ファイルの処理＜ここまで＞


#================================
# csvファイルのデータ内カンマ処理
#================================

sub csv { 
    my (@line) = @_;
	# CSVファイルの "" 処理
	if ( $line[0] =~ /^"/ ) {		# 行頭が " の場合
		if ( $line[0] =~ /"$/ ) { 
			last; 					# 「 " で始まり " で終わる」場合は、本loopを抜ける
		} else {					# そうでない（ "で始まるが " で終わっていない）場合は、以下の処理をする
			my $i=1; 				# loop用の変数
			do { 
				$line[0] = "$line[0]\,$line[$i]";	# 1列後方のデータを,付で接続し、
				foreach ($i..$#line-1) { 			# 1列ずつ前方にずらす
					$line[$_] = $line[$_+1];
				}
				$i++;
			} until ( $line[0] =~ /"$/ ) 			# 接続後の末尾が"になるまで繰り返す
		}
	}
    return @line;
}

#=============
# uniq 処理
#=============
sub uniq { 
	my (@array) = @_;
	my %appearance;
	my @unique = grep !$appearance{$_}++, @array;
	return @unique;
}

#=============
# Close 処理
#=============
#	close(STDOUT);
	close(OUT);


__END__
:endofperl
