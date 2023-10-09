@rem = '  TemplateOut_1row.pl ��s�f�[�^(���f�[�^)�� IAMCTemplate�o��

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
# TemplateOut_1row.pl		��s�f�[�^(���f�[�^)�� IAMCTemplate�o��


#==========
# �\��
#==========
#     
#     +-- here / TemplateOut_1row.pl  	���̃t�@�C���A�v�Z�̖{��
#			|
#			+-- REF 	�Q�ƃf�[�^�p�t�H���_
#			|			(���ږ�).csv			�ʍ��ڂ̃f�[�^�t�@�C���A�u�N�~�����v�`����csv�t�@�C��
#			|									IEA�u���E�U�̏o�̓t�@�C���𖳉��H�Ŏg��
#			|									�N�̃^�C�g���s��1�s��
#			|			unit.txt				(���ږ�)�|�P�ʂ̒�`�t�@�C���A�^�u��؃e�L�X�g
#			+-- GRAPH 	�o�͗p�t�H���_
#				|		log.txt					�G���[���̊m�F�t�@�C��
#				+-- (���ږ�1) 					���ږ��̃O���t���[�t�H���_
#				|		(���ږ�)_�n�於1.gif
#				|		(���ږ�)_�n�於2.gif
#				|		(���ږ�)_�n�於3.gif
#				+-- (���ږ�2) 					���ږ��̃O���t���[�t�H���_
#				|		(���ږ�)_�n�於1.gif
#				|		(���ږ�)_�n�於2.gif
#				|		(���ږ�)_�n�於3.gif
#				+-- (���ږ�n) 					���ږ��̃O���t���[�t�H���_

#=============
# �t���[
#=============

# (1) �^�C�g���s�i�N�j�Ǎ�
# (2) �f�[�^�s�i1�s/1�n��j�Ǎ�
# (3) �O���t�t�@�C���̏o��
# (4) (2)-(3)��n�搔�����J��Ԃ�


#=============
# �ݒ�
#=============

use strict;
use warnings;
use GD::Graph::linespoints;
use GD::Graph::points;
use File::Path;

my $reference_derectory = "$ARGV[0]";	# "REF"; # �Q�ƃf�[�^�̏ꏊ�ACSV�O��i���̂����`��SWITCH�ɂ���j
my $result_derectory = "$ARGV[1]";	# "GRAPH1";	# ���ʃf�[�^�̏ꏊ�ACSV�O��i����j
my $unit_filename = "unit.txt";	# ���ږ��ƒP�ʂ̃t�@�C��

my $file_output = "IAMCTemplate_out_countries.csv"; 	# �o�̓t�@�C��
my @title_line = qw( MODEL SCENARIO REGION VARIABLE UNIT );	# year�̑O�܂ł̔z��
my @title_char = @title_line;	# �O���t�ɓn���f�[�^

my $code_filename = "CC.txt";	# �R�[�h��`�t�@�C���A�^�u��؃e�L�X�g
my $target_code_no = 1;	# �����Ώۂ̗�ԍ� ���R�[�h��`�t�@�C���iA��=0, B��=1�j
my $add_code_no = 5;	# �t�^�Ώۂ̗�ԍ� ���R�[�h��`�t�@�C��

#=============
# ����
#=============

# rmtree($result_derectory);
# mkdir $result_derectory or die "$result_derectory ���쐬���邱�Ƃ��ł��܂���B : $!";
# open(STDOUT,">$result_derectory/log.txt");

open (OUT, ">$result_derectory/$file_output") or die "Can't open: $file_output: $!";	# �e���v���[�g�o��
chdir $reference_derectory;

#=============
# �R�[�h��`�n�b�V���̍쐬
#=============

open (IN, "$code_filename") or die "Can't open: $code_filename: $!";

my $line = <IN>;	# �擪�s���ǂݍ���ŕ��u
# chomp ($line);
# my @title = split(/\t/, $line);
# print "\@title : \t@title\t END \n\n";	# �m�F�p�o��


my %code_match_hash; 	# ��=>�n�� �R�[�h�}�b�`�p�̃n�b�V������
while  (<IN>)  {
	chomp;
	my @for_hash = split(/\t/);	# �^�u�ŕ���
	# ��ԍ��ɂ��z�� => ������L�[�Ƃ���n�b�V��
	$code_match_hash{$for_hash[$target_code_no]} = $for_hash[$add_code_no];	
	print "\%code_match_hash : $for_hash[$target_code_no] -> $code_match_hash{$for_hash[$target_code_no]}\n";	# �m�F�p�o��
}
close(IN);
print "\n";	# �m�F�p�o��

#=============
# �R�[�h��`�n�b�V���̃L�[���X�g���擾����
#=============

my @regions_aggregated = uniq(sort(values(%code_match_hash)));
print "\@regions_aggregated : @regions_aggregated \n"; 	# �m�F�p�o��

if ( $regions_aggregated[0] eq '' ) { 	# ��f�[�^����������폜
							# sort��uniq��Ȃ̂�[0]�Ԗڂ̗v�f�������`�F�b�N���Ă���
	print "shift�����O  \$regions_aggregated[0] : $regions_aggregated[0] \t \$regions_aggregated[1] : $regions_aggregated[1] \n"; 	# �m�F�p�o��
	shift(@regions_aggregated);	# $years[0] �͍��R�[�h������O��Ȃ̂�
	print "shift������  \$regions_aggregated[0] : $regions_aggregated[0] \t \$regions_aggregated[1] : $regions_aggregated[1] \n"; 	# �m�F�p�o��
}


#=============
# �P�ʃn�b�V���̍쐬
#=============

open (IN, "$unit_filename") or die "Can't open: $unit_filename: $!";

my %item_unit_hash; 	# ���ږ�=>�P�� �}�b�`�p�̃n�b�V������
while  (<IN>)  {
	chomp;
	s/(.csv)//ig;	# �m�F�p�o��
	s/(.txt)//ig;	# �m�F�p�o��

	my @for_hash = split(/\t/);	# �^�u�ŕ���
	# ��ԍ��ɂ��z�� => ������L�[�Ƃ���n�b�V��
	$item_unit_hash{$for_hash[0]} = $for_hash[1];	
	print "\%item_unit_hash : $item_unit_hash{$for_hash[0]} \t $for_hash[0] -> $for_hash[1] \n";	# �m�F�p�o��
}
close(IN);
print "\n";	# �m�F�p�o��


#=============
# �^�C�g���s�̓Ǎ�
#=============

my $file; 
my @years;
my ($year, $region);
# my %yeardata;	# �N�~�n��R�[�h�̒l�������邽�߂̃n�b�V������

while ( $file = glob("*.csv") ) { 	 # 1�t�@�C���̏������������灄

	open(IN,"$file");
	print "\n\n�����J�n�@\$file : $file\n"; 	# �m�F�p�o��
	$file =~ s/\.csv//;
	my $unit = "$item_unit_hash{$file}";

	mkdir "../$result_derectory/$file" or die "$file �t�H���_���쐬���邱�Ƃ��ł��܂���B : $!";

	# CSV�t�@�C���̐擪�s����N�̒�`���擾

	my $line = <IN>;	# �擪�s�̓Ǎ� �u�N�~���v�`���̃t�@�C���@�N�^�C�g���s
	chomp ($line);

	@years = split(/\,/, $line);
	shift(@years);	# $years[0] �̗�́A���R�[�h������O��Ȃ̂�

# �^�C�g���s�̓Ǎ� �������܂Ł�

#=============
# �^�C�g���s�̏o�́i����̂݁j
#=============

	print "���uIAMCTemplate�v�`���t�@�C���̏o�́F�^�C�g���s��\n"; 	# �m�F�p�o��

	my ($title_line, $year);
	foreach $title_line(@title_line) { print OUT "\"$title_line\","; }	# �^�C�g���s�̓t�@�C�����ɏo�͂��Ă���
	foreach $year(@years) { print OUT "\"$year\","; }	# ��t�@�C���Ԃ� year �̈�v��O��Ƃ��Ȃ�
	print OUT "\n"; 

# �^�C�g���s�̏o�� �������܂Ł�


#=============
# �f�[�^�s�̓Ǎ��i1�s1���j
#=============

	# �f�[�^�t�@�C���̏�����
	($year, $region) = undef;

	while (<IN>) {	#�f�[�^�s�̏����J�n

		if ( /^COUNTRY/ ) { next; }	# �]�v�ȍs�̏ꍇ��SKIP

		chomp;
		my @line = split(/\,/);	# �Ƃ肠�����J���}�ŋ�؂�
		@line = csv(@line);	# CSV�t�@�C���� "�Z�����J���}" ����

		$region = $line[0];		# �擪�f�[�^ $line[0] �́u�����v�Ȃ̂�

		shift(@line);	# @line �� @years �ɑΉ����Ă���̂�

#		print "\n\$region : $region \n"; 	# �m�F�p�o��
#		print "\@line : @line \n"; 	# �m�F�p�o��

		my $sum_region = undef;	
		$sum_region = $code_match_hash{$region}; 	# ������n��R�[�h
		print "\$sum_region : $sum_region\t@line \n"; 		# ��`�ρE�W�v�Ώۂ̒n��ɂ��Ă�OUT1�Ƀ��X�g���o��
		unless ($sum_region) { next; }		# ������n��R�[�h�������ꍇ�͎��̍s��


	#==========================
	# �f�[�^�s�̏o�́i1�s�������j
	#==========================

	print "���uIAMCTemplate�v�`���t�@�C���̏o�́F�f�[�^�s��\n"; 	# �m�F�p�o��

	my ($title_line, $year);

	$title_char[3] = $file;	# �w�W��
	$title_char[2] = $region;	# �n��
	foreach (0..4) { print OUT "\"$title_char[$_]\","; }		# ������f�[�^�̏o��

	foreach (0..$#years) { 
		print OUT $line[$_];	# �f�[�^�̏o��
		print OUT ","; 	# ��؂蕶���̏o��
#		print OUT "$indicator{$year},"; 	# �w�W�f�[�^�̏o��
#		print "\%indicator {$year} {$region} : $indicator{$year}\n"; 	# �m�F�p�o��
	}
	print OUT "\n"; 


#	$title_char[3] = "ChangeRate_".$title;	# �w�W��
#	$title_char[4] = $title_char[4]."/y"; 	# �P��
#	foreach $region(@regions) {  �ω����̏o��
#	} 	# loop by $region 
#	print OUT "\n"; 

	# �uIAMCTemplate�v�`���t�@�C���̏o�́icsv�j�������܂Ł�

		#===============
		# �O���t�̍쐬
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


		print "\$region : $region \n"; 	# �m�F�p�o��
#		print "\@labels : @labels \n"; 	# �m�F�p�o��
		print "\@dataset : @dataset \n"; 	# �m�F�p�o��

		my $gd = $graph->plot(\@data) or die $graph->error;


		$region =~ s/Cura�ao/Curacao/ig;	# �t�@�C�����G���[�ʎw��
		$region =~ s/C�te/Cote/ig;	# �t�@�C�����G���[�ʎw��
		$region =~ s/C?te/Cote/ig;	# �t�@�C�����G���[�ʎw��
		$region =~ s/R?union/Reunion/ig;	# �t�@�C�����G���[�ʎw��

		$region =~ s/(Memo: )//ig;	# �t�@�C�����֑̋������͍폜
		$region =~ s/(Memo\*: )//ig;	# �t�@�C�����֑̋������͍폜
		$region =~ s/[\.\,\"\'\*]//ig;	# �t�@�C�����֑̋������͍폜
		$region =~ s/[\/]/_/ig;	# �t�@�C�����֑̋������͍폜

		print "3 : $region \n"; 	# �m�F�p�o��


		open(IMG, ">../$result_derectory/$file/($file)\_$region.gif") or die "$!";
		binmode IMG;
		print IMG $gd->gif;
		close IMG;

		print "\($file)\_$region.gif Completed! \n"; 	# �m�F�p�o��


	}			# �f�[�^�s���̏����I��

	print OUT "\n"; 
}	# 1�t�@�C���̏����������܂Ł�


#================================
# csv�t�@�C���̃f�[�^���J���}����
#================================

sub csv { 
    my (@line) = @_;
	# CSV�t�@�C���� "" ����
	if ( $line[0] =~ /^"/ ) {		# �s���� " �̏ꍇ
		if ( $line[0] =~ /"$/ ) { 
			last; 					# �u " �Ŏn�܂� " �ŏI���v�ꍇ�́A�{loop�𔲂���
		} else {					# �����łȂ��i "�Ŏn�܂邪 " �ŏI����Ă��Ȃ��j�ꍇ�́A�ȉ��̏���������
			my $i=1; 				# loop�p�̕ϐ�
			do { 
				$line[0] = "$line[0]\,$line[$i]";	# 1�����̃f�[�^��,�t�Őڑ����A
				foreach ($i..$#line-1) { 			# 1�񂸂O���ɂ��炷
					$line[$_] = $line[$_+1];
				}
				$i++;
			} until ( $line[0] =~ /"$/ ) 			# �ڑ���̖�����"�ɂȂ�܂ŌJ��Ԃ�
		}
	}
    return @line;
}

#=============
# uniq ����
#=============
sub uniq { 
	my (@array) = @_;
	my %appearance;
	my @unique = grep !$appearance{$_}++, @array;
	return @unique;
}

#=============
# Close ����
#=============
#	close(STDOUT);
	close(OUT);


__END__
:endofperl
