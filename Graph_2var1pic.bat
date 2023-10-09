@rem = ' 2�ϐ��̃O���t���@Graph_2var1pic.bat�@$ARGV[2]�t�@�C����1 [3]�ϐ���1 [4]�t�@�C����2 [5]�ϐ���2 [6]�����W��

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

# bat�R�}���h ���u��

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

# perl %0 $ARGV[0]���̓t�H���_��%INPUT% [1]�o�̓t�H���_��%OUTPUT%\EI $ARGV[2]�t�@�C����1 [3]�ϐ���1 [4]�t�@�C����2 [5]�ϐ���2 [6]�����W�� > ���O�t�@�C����%OUTPUT%\EI\log_Energy_Intensity.txt



#! /usr/local/bin/perl
# Graph_2row21pic.pl	2�n���̃f�[�^���d�˂ăO���t�o��

#==========
# �\��
#==========
#     
#     +-- here / Graph_2rows1pic.bat  	���̃t�@�C���A�v�Z�̖{��
#			|
#			+-- REF2 	�Q�ƃf�[�^�p�t�H���_
#			|			IAMCTemplate.csv		2010�N�`    	�^�C�g���s��1�s��
#			|			IAMCTemplate_ref.csv	1960�`2019�N	����
#			|									
#			+-- GRAPH2 	�o�͗p�t�H���_
#				 		log.txt					�G���[���̊m�F�t�@�C��
#				 		(�ϐ���)_�V�i���I��_�n�於1.gif
#				 		(�ϐ���)_�V�i���I��_�n�於2.gif
#				 		(�ϐ���)_�V�i���I��_�n�於n.gif

#=============
# �t���[
#=============

# (1) IAMCTemplate_out.csv(ref)�Ǎ��@�� �^�C�g���s�擾@years_ref �� �����}�b�`($VARIABLE/$SCENARIO)�� �f�[�^�s�擾@var_ref
# (2) IAMCTemplate.csv(future)�Ǎ��@�� �^�C�g���s�擾@years �� �����}�b�`($VARIABLE/$SCENARIO)�� �f�[�^�s�擾@var
# (3) (@var), (@var_ref) ����N�l�Ő��K������
# (4) (@var), (@var_ref) �������v���b�g���ꂽ�O���t�t�@�C���̏o��

#=============
# �ݒ�
#=============

use strict;
use warnings;
use GD::Graph::linespoints;
use GD::Graph::points;
use File::Path;

@ARGV = map { $_ =~ s/\^//ig; $_ } @ARGV; 	# bat�R�}���h�p�̃G�X�P�[�v����(^)�̍폜

#�@$ARGV[2]�t�@�C����1 [3]�ϐ���1 [4]�t�@�C����2 [5]�ϐ���2 [6]�����W��

my $reference_derectory = "$ARGV[0]";	# "REF2";	# �Q�ƃf�[�^�̏ꏊ�ACSV�O��i���̂����`��SWITCH�ɂ���j
my $result_derectory = "$ARGV[1]";	# "GRAPH2";	# ���ʃf�[�^�̏ꏊ�ACSV�O��i����j

my @files = ("$ARGV[2]", "$ARGV[4]");

my @variables_ref = "$ARGV[3]";
my @variables = "$ARGV[5]";
my $BaseYear = "$ARGV[6]";	# ��N�@# �����ɂ���ꍇ��0�@

# �t�H�[�}�b�g�w��
my @title_line  = qw( MODEL SCENARIO REGION VARIABLE UNIT );	# year�̑O�܂ł̔z��
# my @regions = qw( USA CHN JPN );
my @regions = qw( XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF );	# �n��̔z��@qw( USA XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF ASIA2 World );

# my @files = qw( IAMCTemplate_out.csv IAMCTemplate.csv ); 	# �Q�Ɨp�f�[�^�@�]���Ώۂ̃f�[�^ [0]�Ԃ�Ref IAMCTemplate_ref.csv

my @scenarios = qw( Baseline 2C ); 	# �V�i���I�̔z�� qw( Baseline 1.5C 2C 2.5C WB2C );
my @scenarios_ref = qw( Reference ); 	# REF�V�i���I�̔z�� @scenarios�ɑΉ��A�ȗ�����[0]�̒l


#=============
# ����
#=============

# rmtree($result_derectory);
# mkdir $result_derectory or die "$result_derectory ���쐬���邱�Ƃ��ł��܂���B : $!";
# open(STDOUT,">$result_derectory/log.txt");
chdir $reference_derectory;

my ($line, @line);
my (@years, @var, @title_char);	# �O���t�ɓn���f�[�^
my (@years_ref, @var_ref );	# �O���t�ɓn���f�[�^
my ($year, %var, %var_ref);	# �A���N�ɕϊ����邽�߂̃n�b�V���ƔN�L�[�A$var{$year}, $var_ref{$year}
my ($file, $region, $variable, $variable_no, $scenario, $scenario_no ) = undef; 	# loop���Ŏg���ϐ�

print "\@ARGV : @ARGV \n"; 	# �m�F�p�o��
print "\@variables : @variables \n"; 	# �m�F�p�o��
print "\@variables_ref : @variables_ref "; 	# �m�F�p�o��
print "\t NO MATCH!! " unless ( $#variables == $#variables_ref );
print "\n"; 	# �m�F�p�o��

foreach (0..$#scenarios) { $scenarios_ref[$_] = $scenarios_ref[$#scenarios_ref] unless ( $scenarios_ref[$_] ); }
print "\@scenarios : @scenarios \n"; 	# �m�F�p�o��
print "\@scenarios_ref : @scenarios_ref \n"; 	# �m�F�p�o��

#=============
# 1�����̏���		# �ϐ��A�V�i���I�A�n��̃Z�b�g
#=============

foreach $variable_no(0..$#variables) { 	# �ϐ���loop

foreach $scenario_no(0..$#scenarios) { 	# �V�i���I��loop
foreach $region(@regions) { 	# �n���loop

	print "\n\n�ySTART�z \t variable : $variables[$variable_no] \t scenario : $scenarios[$scenario_no] \t region : $region \n"; 	# �m�F�p�o��

	foreach $file(@files) { 	# �t�@�C����loop

		(@years, @var, @title_char) = undef;	# ������

		open(IN,"$file");
		$line = <IN>;	# �擪�s�̓Ǎ��@�N�^�C�g���s
		$line =~ s/\"(\b.*?\b)\"/$1/ig;	# �ŏ��}�b�`�@ "*", �p�^�[��
		chomp ($line);
		@line = split(/\,/, $line);	# �Ƃ肠�����J���}�ŋ�؂�
		@years = @line[$#title_line+1..$#line]; 	# �^�C�g���s����N���擾

		print "\n\$file : $file \n \@years : @years \n"; 	# �m�F�p�o��

		# ��N�����i���̏ꏊ�j

		# �ߋ�Ref�������V�i���I���Ń}�b�`�ΏۂƂȂ�V�i���I��/�ϐ��������ւ���@$files[0]�Ȃ�Ref
		if ( $file eq $files[0] ) { # Ref Past
			$scenario = $scenarios_ref[$scenario_no];
			$variable = $variables_ref[$variable_no];
		} else { # Future
			$scenario = $scenarios[$scenario_no];
			$variable = $variables[$variable_no];
		}

		while (<IN>) {	#�f�[�^�s�̏����J�n

			s/\"(\b.*?\b)\"/$1/ig;	# �ŏ��}�b�`�@ "*", �p�^�[��
			chomp;
			@line = split(/\,/);	# �Ƃ肠�����J���}�ŋ�؂�
#			print "\n \@line : @line \t"; 	# �m�F�p�o��

			unless ( $line[1] ) { 
				next; 
			}
			if ( ($line[1] eq $scenario)&&($line[2] eq $region)&&($line[3] eq $variable) ) { 
				# VARIABLE SCENARIO region ����v������
				@var = @line[$#title_line+1..$#line]; 	# �N�ɑ�������l���擾
				@title_char = @line[0..$#title_line]; 	# �q�b�g�����s�̃^�C�g�����擾
				last;
			}

		} 	# #�f�[�^�s�̏��������܂�
		close(IN);

		# ��N�����F�F�������������灄
		my $BaseYear_num = "none"; 	# ��N�l�̔z��ԍ��A@years �̒��� ��N�����Ԗڂ�
		while ( my ($i,$j) = each @years ) {
			$BaseYear_num = $i if ($j==$BaseYear); 
		}
		if ( $BaseYear_num eq "none" ) { 	# �����l�̂܂܂Ȃ�A�G���[�o��
			print "�y��N($BaseYear)���A���̓f�[�^�Ɋ܂܂�Ă��܂���z \n"; 
		} else {
			print "�y��N�l�� $BaseYear_num �Ԗڂ̗v�f�ł��z\n" ;
		}
		# ��N�����F�F�����������܂Ł�
		# ��N�l�Ő��K�����鏈���i�ړ���j
		if ($BaseYear) {
			my $val_baseYear = $var[$BaseYear_num];
			if ( $val_baseYear ) { # ��N�̒l�����݂���ꍇ
				foreach (@var) { $_ =  $_ / $val_baseYear; }
				# @var = map { $_ / $val_baseYear } @var; 	# 9/16 �ύX
				$title_char[4] .= " (val($BaseYear)\=1\.0)";
			} else {
				print "�y��N�l���A���݂��܂���z\n";
			}
		}  # �������܂Ł���N�l�Ő��K�����鏈��

		if ( $file eq $files[0] ) { 	# �Q�ƃf�[�^��XY�l��ʕϐ��Ɋi�[����
			@years_ref = @years;
			@var_ref = @var;
		}

	} 	# �t�@�C����loop

	# ������ �f�[�^��Graph �ɓn��

	print "\n\$region : $region \n"; 	# �m�F�p�o��
	print "\@years : @years \n"; 	# �m�F�p�o��
	print "\@years_ref : @years_ref \n"; 	# �m�F�p�o��
	print "\@var : @var \n"; 	# �m�F�p�o��
	print "\@var_ref : @var_ref \n"; 	# �m�F�p�o��

	# �O���t�p�n�b�V���i�N���L�[�Ƃ��Ēl��Ԃ��j�̍쐬
	(%var, %var_ref)= undef;	# �O���t�ɓn�����߂̃n�b�V���A$var{$year}

	foreach (0..$#years) { 	# �N��loop
		$var{$years[$_]} = $var[$_];
	} 	# �N��loop

	foreach (0..$#years_ref) { 	# �N��loop
		$var_ref{$years_ref[$_]} = $var_ref[$_];
	} 	# �N��loop

	# �e�N�̔z��ɕϊ�����

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
#		print "\$i:$i \t \$eachyear[$i]:$eachyear[$i] \t \$var_eachyear[$i]:$var_eachyear[$i] \t \$var_ref_eachyear[$i]:$var_ref_eachyear[$i] \n"; 	# �m�F�p�o�� ���폜�֎~/�s�v���̓R�����g�A�E�g��

	}

	# �O���t�n���p�z��̊m�F
	print "\n���N�ϊ��̒���̊m�F��\n"; 	# �m�F�p�o��
	print "\$years_min : $years_min \n"; 	# �m�F�p�o��
	print "\$years_max : $years_max \n"; 	# �m�F�p�o��
	print "\@years : @years \n"; 	# �m�F�p�o��
	print "\@years_ref : @years_ref \n"; 	# �m�F�p�o��

	print "\n\@eachyear : @eachyear \n"; 	# �m�F�p�o��
	print "\@var_eachyear : @var_eachyear \n"; 	# �m�F�p�o��
	print "\@var_ref_eachyear : @var_ref_eachyear \n"; 	# �m�F�p�o��

	# �O���t�� @eachyear, @var_eachyear, @var_ref_eachyear ��n��
	&graph(\@eachyear, \@var_eachyear, \@var_ref_eachyear, \@title_char); 	#���t�@�����X�n��

} 	# �n���loop
} 	# �V�i���I��loop
} 	# �ϐ���loop


#=============
# Graph ����
#=============
sub graph { 

	my ($labels, $dataset1, $dataset2, $title_char ) = @_; 	# �z��̃��t�@�����X��ϐ��ň�U�󂯂�

	my @labels = @$labels; 	# �f���t�@�����X
	my @dataset1 = @$dataset1; 	# �f���t�@�����X
	my @dataset2 = @$dataset2; 	# �f���t�@�����X
	my @title_char = @$title_char; 	# �f���t�@�����X

	print "\n���������� Graph�T�u���[�`����\n"; 	# �m�F�p�o��
	print "\@labels : @labels \n"; 	# �m�F�p�o��
	print "\@dataset1 : @dataset1 \n"; 	# �m�F�p�o��
	print "\@dataset2 : @dataset2 \n"; 	# �m�F�p�o��
	print "\@title_char : @title_char \n"; 	# �m�F�p�o��

	my $MODEL	 = $title_char[0]; 	# ���w��
	my $SCENARIO = $title_char[1]; 
	my $REGION	 = $title_char[2]; 
	my $VARIABLE = $title_char[3]; 
	my $UNIT	 = $title_char[4]; 

		# GD::Graph����	
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
#		$graph->set_legend_font('GD::gdTinyFont'); 	# ���t�H���g�� �vGD::Text 

		my $gd = $graph->plot(\@data) or die $graph->error;

		foreach ($REGION, $SCENARIO, $VARIABLE) { 	# �t�@�C�����Ɏg���ϐ����w��
			s/\�t/_/ig;	# �t�@�C�����G���[�ʎw��
			s/\?/_/ig;	# �t�@�C�����G���[�ʎw��
			s/[\.\,\"\'\*]//ig;	# �t�@�C�����֑̋������͍폜
			s/[\/]/_/ig;	# �t�@�C�����֑̋������̒u��
			s/[\|]/_/ig;	# �t�@�C�����֑̋������̒u��
		}

		open(IMG, ">../$result_derectory/($VARIABLE)\_$SCENARIO\_$REGION.gif") or die "$!";
		binmode IMG;
		print IMG $gd->gif;
		close IMG;

		print "($VARIABLE)\_$SCENARIO\_$REGION.gif Completed! \n"; 	# �m�F�p�o��

} 	# graph �I��


#=============
# uniq ����
#=============
sub uniq { 
	my (@array) = @_;
	my %appearance;
	my @unique = grep !$appearance{$_}++, @array; 	# @array ���L�[�Ƃ���n�b�V����]�����A���o��Ȃ� @unique �ɒǉ�
	return @unique;
} 	# uniq �I��

#=============
# Close ����
#=============
# close(STDOUT);

__END__
:endofperl

