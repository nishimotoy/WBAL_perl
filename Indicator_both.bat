@rem = '  Indicator_both.pl �ߋ�/�����̗����ɑΉ����� revised from Indicator_step_f.pl

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

# bat�R�}���h ���u��
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
# Indicator_step.pl	2�ϐ����w�肵�Ďw�W���Z�o�A�N�Ԋu���w��

#==========
# �\��
#==========
#     
#     +-- here / Indicator_step.pl  	���̃t�@�C���A�v�Z�̖{��
#			|    Test.bat				���o�͎w��R�}���h
#			|
#			+-- REF2 	�Q�ƃf�[�^�p�t�H���_
#			|			IAMCTemplate_ref.csv	���̓t�@�C��	$file_input
#			|									
#			+-- GRAPH3 	�o�͗p�t�H���_
#						log.txt					�G���[���̊m�F�t�@�C��
#						(�ϐ���)_�V�i���I��_�n�於.gif
#						(�w�W��)_�V�i���I��_�n�於.gif
#						(Change_Rate_�w�W��)_�V�i���I��_�n�於.gif
#						IAMCTemplate_out.csv	�o�̓t�@�C��	$file_output

#=============
# �t���[
#=============

# (1) IAMCTemplate_ref.csv�Ǎ��@�� �^�C�g���s�擾@years �� �����}�b�`($VARIABLE/$SCENARIO)�� �f�[�^�s�擾@var
# (2) �擾���� @years, @var ���e�N�ɕϊ� �� @eachyear, @var_eachyear
# (2-2) �w�肵���Ԋu�� @var_step(@year_step) �ɕϊ�����B��N($BaseYear)�̑O��̎w��Ԋu($StepYear) �� @var�㏑��
# (3) �w�W�A���̕ω����̎Z�o�� @indicator, @indicator_change_rate
# (4) �w�W�̐��l�t�@�C��(csv)�̏o��	�� $file_output
# (5) �O���t�t�@�C���̏o�́� @var_eachyear, @indicator, @indicator_change_rate
# (6) �w�W�̃O���t�t�@�C���̏o�́� @indicator
# (7) �ω����̃O���t�t�@�C���̏o�́� @indicator_change_rate

#=============
# �ݒ�
#=============

use strict;
use warnings;
use GD::Graph::linespoints;
use GD::Graph::points;
use File::Path;

my $reference_derectory = $ARGV[0];	# "REF2";	# �Q�ƃf�[�^�̏ꏊ�ACSV�O��i���̂����`��SWITCH�ɂ���j
my $result_derectory = $ARGV[1];	# "GRAPH3\TYPE\Indicator";	# ���ʃf�[�^�̏ꏊ�ACSV�O��i����j

# �t�H�[�}�b�g�w��
my @title_line = qw( MODEL SCENARIO REGION VARIABLE UNIT );	# year�̑O�܂ł̔z��
my @regions = qw( XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF );	# �n��̔z��@qw( USA XE25 XER TUR XOC CHN IND JPN XSE XSA CAN BRA XLM CIS XME XNF XAF ASIA2 World );
my $unit;

my $type = $ARGV[2];	# past or future

my $file_input = "IAMCTemplate.csv"; 	# ���f�[�^�t�@�C�������� "IAMCTemplate_ref.csv"; ���ߋ�
if ($type eq "PAST") { $file_input = "IAMCTemplate_ref.csv"; }

my $file_output = "IAMCTemplate_i_future.csv"; 	# �o�̓t�@�C��
if ($type eq "PAST") { $file_output = "IAMCTemplate_i_past.csv"; }

my @scenarios = qw( Baseline 2C ); 	# �V�i���I�̔z�� qw( Reference );  qw( Baseline 1.5C 2C 2.5C WB2C );
if ($type eq "PAST") { @scenarios = qw( Reference ); }

my @variables_for_Indicator = @ARGV[3..6];
# [0]�w�W�� [1]�ϐ�1 [2]���Z�q [3]�ϐ�2 �̏��ԂŎw�肷��	
# �ϐ�1[1]�ƕϐ�2[3]�̈ʒu��ς����ꍇ�̓R�[�h�ύX���K�v�A�w�W��[0]�Ɖ��Z�q[2]�̓^�C�g���\���Ɏg�p

@variables_for_Indicator = map { $_ =~ s/\^//ig; $_ } @variables_for_Indicator; 	# bat�̃G�X�P�[�v�����̍폜

my $BaseYear = 2010;	# ��N�@�w�W�ω��� (@indicator_change_rate) ���Ŏg�p
my $StepYear = 5;	# �X�e�b�v�N�@�ω������v������P��

#=============
# ����
#=============
# rmtree($result_derectory);
# mkdir $result_derectory or die "$result_derectory ���쐬���邱�Ƃ��ł��܂���B : $!";
# open(STDOUT,">$result_derectory/log.txt");

my ($line, @line);
my (@years, @var, @title_char);	# �O���t�ɓn���f�[�^
my ($file, $region, $variable, $variable_no, $scenario, $scenario_no ) = undef; 	# loop���Ŏg���ϐ�
my $title;	# �w�W��
my (%indicator, %indicator_change_rate, %indicator_change_rate_baseYear, %indicator_change_rate_priorYear ) = (); 	# �w�W�ƕω����̃n�b�V���̏�����

print "\@variables_for_Indicator : @variables_for_Indicator \n"; 	# �m�F�p�o��
print "\$type : $type \t \$file_input : $file_input \t \$file_output : $file_output \t \@scenarios : @scenarios \n"; 	# �m�F�p�o��

#=============
# 1�����̏���		# �ϐ��A�V�i���I�A�n��̃Z�b�g
#=============

chdir $reference_derectory;
foreach $scenario(@scenarios) { 	# �V�i���I��loop

	foreach $region(@regions) { 	# �n���loop

		my (@var1, @var2, @indicator, @indicator_change_rate ) = undef; 	# �w�W�Ƃ��̎Z�o�ɗp����ϐ��̏�����
		my (@indicator_change_rate_baseYear, @indicator_change_rate_priorYear ) = undef; 	# �w�W�ω����̐��K���p
		my ($unit_var1, $unit_var2 ) = undef; 	# �w�W�p�̒P��

		foreach $variable($variables_for_Indicator[1],$variables_for_Indicator[3]) { 	# �ϐ���loop

			print "\n\n�ySTART�z \t variable : $variable \t scenario : $scenario \t region : $region \n"; 	# �m�F�p�o��

			foreach $file($file_input) { 	# �t�@�C����loop

				(@years, @var, @title_char) = ();	# ������
				print "\$file : $file \n"; 	# �m�F�p�o��

				open(IN,"$file") or die "Can't open: $file: $!";	# �w��`���̏o��
				$line = <IN>;	# �擪�s�̓Ǎ��@�N�^�C�g���s
				print "\$line : $line \n"; 	# �m�F�p�o��
				$line =~ s/\"(\b.*?\b)\"/$1/ig;	# �ŏ��}�b�`�@ "*", �p�^�[��
				chomp ($line);
				@line = split(/\,/, $line);	# �Ƃ肠�����J���}�ŋ�؂�
				print "\@line : @line \n"; 	# �m�F�p�o��
				@years = @line[$#title_line+1..$#line]; 	# �^�C�g���s����N���擾
				print "\n\$file : $file \n \@years : @years \n \@line : @line \n"; 	# �m�F�p�o��

				while (<IN>) {	#�f�[�^�s�̏����J�n
					s/\"(\b.*?\b)\"/$1/ig;	# �ŏ��}�b�`�@ "*", �p�^�[��
					chomp;
					@line = split(/\,/);	# �Ƃ肠�����J���}�ŋ�؂�
#					unless ( $line[1] ) { next; }
					if ( ($line[1] eq $scenario)&&($line[2] eq $region)&&($line[3] eq $variable) ) { 
						# VARIABLE SCENARIO region ����v������
						@var = @line[$#title_line+1..$#line]; 	# �N�ɑ�������l���擾
						@title_char = @line[0..$#title_line]; 	# �q�b�g�����s�̃^�C�g�����擾
						last; 	# �q�b�g������last��
					}
				} 	# #�f�[�^�s�̏��������܂�
				close(IN);
			} 	# �t�@�C����loop

			print "\n���Ǎ��I���� \t \$region : $region \t \$variable : $variable \t \$scenario : $scenario \n"; 	# �m�F�p�o��
			print "\@years : @years \n"; 	# �m�F�p�o��
			print "\@var : @var \n"; 	# �m�F�p�o��

			# @var ���� ���������灄
			# @var ������ɓ����ĂȂ��ꍇ�́A�ȍ~�̏�����SKIP�i@variables_for_Indicator �Ƀ_�~�[����ꂽ�ۂɓ����j
			unless ( @var ) { print "SKIPPED \n"; next; } 	

			# eachyear�����i@years, @var ��n���� @eachyear, @var_eachyear ���󂯎��j
			my ($eachyearRef, $var_eachyearRef ) = &eachyear(\@years, \@var);	# ���t�@�����X�n���A���t�@�����X���
			my @eachyear = @$eachyearRef; 	# �f���t�@�����X
			my @var_eachyear = @$var_eachyearRef; 	# �f���t�@�����X

			# �O���t�n���p�z��̊m�F
#			print "\n��&eachyear�い\n"; 	# �m�F�p�o��
#			print "\n\@eachyear : @eachyear \n"; 	# �m�F�p�o��
#			print "\@var_eachyear : @var_eachyear \n"; 	# �m�F�p�o��

			# �O���t�� @eachyear, @var_eachyear ��n��
			&graph(\@eachyear, \@var_eachyear, \@title_char); 	#���t�@�����X�n��
			# @var ���� �������܂Ł�

			if (1) {	# @var_step ���� ���������灄
				# @eachyear, @var_eachyear �̃n�b�V����
				my %hash_eachyear = ();
				@hash_eachyear{@eachyear} = @var_eachyear; #�n�b�V���̃X���C�X
#				print "\%hash_eachyear \n"; 	# �m�F�p�o��
#				for my $key (sort keys %hash_eachyear){ print "key: $key value: $hash_eachyear{$key}\n"; }
#				print "\n"; 	# �m�F�p�o��

				# ��N($BaseYear)�𒆐S�ɁA���Ԋu($StepYear)�̔z����쐬
				my @year_step = ();
				for ( my $t=$BaseYear ; $t<=$eachyear[$#eachyear] ; $t=$t+$StepYear ) { 
					push (@year_step, $t);
				}
				for ( my $t=$BaseYear ; $t>=$eachyear[0] ; $t=$t-$StepYear ) { 
					push (@year_step, $t);
				}
				@year_step = uniq(sort(@year_step)); 	# �d��, SKIP�΍�i���for���́A�d���O��j

				my @var_step = ();
				for my $key (@year_step){ 
					push (@var_step, $hash_eachyear{$key}); 
				}
				print "\@year_step : @year_step \n"; 	# �m�F�p�o��
				print "\@var_step : @var_step \n"; 	# �m�F�p�o��

				# @years, @var��u��
				@years = @year_step;
				@var = @var_step;
				&graph(\@years, \@var, \@title_char); 	#�O���t�o��
			}	# @var_step ���� �������܂Ł�


			# @indicator�������������灄
			# �����i��N�̒l�j
			my $BaseYear_num = "none"; 	# ��N�l�̔z��ԍ��A@years �̒��� ��N�����Ԗڂ�
			while ( my ($i,$j) = each @years ) {
				$BaseYear_num = $i if ($j==$BaseYear); 
			}
			if ( $BaseYear_num eq "none" ) { 	# �����l�̂܂܂Ȃ�A�G���[�o��
				print "�y��N($BaseYear)���A���̓f�[�^�Ɋ܂܂�Ă��܂���z\$BaseYear_num : $BaseYear_num \n"; 
			} else {
				print "�y��N�l�� $BaseYear_num �Ԗڂ̗v�f�ł��z\n" ;
			}

			# @indicator�Z�o�̗v�f�}�b�`�i���q�A����j
			if ( $variable eq $variables_for_Indicator[1] ) { 	# ���q�Ɏw�肵���ϐ��ł���ꍇ [1]�w�� 
				@var1 = @var; 	# ���q
				$unit_var1 = $title_char[4]; 	# �P��
				print "\@var1 : @var1 \n"; 	# �m�F�p�o��
				print "\$unit_var1 : $unit_var1 \n"; 	# �m�F�p�o��
			} elsif ( $variable eq $variables_for_Indicator[3] ) { 	# ����Ɏw�肵���ϐ��ł���ꍇ [3]�w�� 
				@var2 = @var; 	# ����
				$unit_var2 = $title_char[4]; 	# �P��
				print "\@var2 : @var2 \n"; 	# �m�F�p�o��
				print "\$unit_var2 : $unit_var2 \n"; 	# �m�F�p�o��
			} 

			# @indicator�Z�o
			if ( (@var1!=0)&&(@var2!=0) ) { 	# ���ϐ������������̂�
				print "�y�w�W�z\@years \t \@var1 \t \@var2 \t \@indicator \t \@indicator_change_rate \n"; 	# �m�F�p�o��
				foreach (0..$#var1) { 
					if ( ($var1[$_])&&($var2[$_]) ) {	# ���ϐ��ɋ��ɒl������N��
						$indicator[$_] = $var1[$_] / $var2[$_]; 	# �w�W�̎Z�o
						$indicator{$years[$_]}{$region} = $indicator[$_]; 	# �w�W�̃n�b�V���� �� csv�o�͗p
						if ($indicator[$_-1]) { 	# �O�N�Ɏw�W������ꍇ
							$indicator_change_rate[$_] = ($indicator[$_]-$indicator[$_-1])/($years[$_]-$years[$_-1]); 	# �w�W�̕ω���
							# $indicator_change_rate{$years[$_]}{$region} = $indicator_change_rate[$_]; 	# �w�W�̕ω����̃n�b�V����
						} else {
							$indicator_change_rate[$_] = undef; 	# �O�N�̎w�W�������Ă���ꍇ��undef
							# $indicator_change_rate{$years[$_]}{$region} = undef; 	# �n�b�V�������l�� undef
						}

					} else {
						$indicator[$_] = undef; 	# �����ꂩ�̒l�������Ă���N�̎w�W��undef
						# $indicator_change_rate[$_] = undef; 	# �����ꂩ�̒l�������Ă���N�̎w�W��undef
					}
				$indicator_change_rate{$years[$_]}{$region} = $indicator_change_rate[$_]; 	# �w�W�̕ω����̃n�b�V����
				print "\t $years[$_] \t $var1[$_] \t $var2[$_] \t $indicator[$_] \t $indicator_change_rate[$_] \n"; 	# �m�F�p�o��
				}
				print "\n\n"; 	# �m�F�p�o��

				# @indicator_change_rate �̋K�i��
				my $val_baseYear = $indicator[$BaseYear_num];
				unless ( $val_baseYear ) { print "�y��N�l���A���݂��܂���z\n"; }

=pod # 9/21
				foreach (0..$#years) {
					if ( $val_baseYear ) { # ��N�̒l�����݂���ꍇ
						$indicator_change_rate_baseYear[$_] = $indicator_change_rate[$_] / $val_baseYear;
						# @indicator_change_rate_baseYear = map { $_ /  $val_baseYear } @indicator_change_rate; 	# 9/15 �ύX
						$indicator_change_rate_baseYear{$years[$_]}{$region} = $indicator_change_rate_baseYear[$_]; 	# �o�͗p�n�b�V��
					} else {
						$indicator_change_rate_baseYear[$_] = undef; 
						# @indicator_change_rate_baseYear = map { $_ = undef; $_ } @indicator_change_rate; 	# 9/15 �ύX
					}
					if ($indicator[$_-1]) { 	# �O��(t-1)�̒l�����݂���ꍇ
						$indicator_change_rate_priorYear[$_] = $indicator_change_rate[$_] / $indicator[$_-1];
					} else {
						$indicator_change_rate_priorYear[$_] = undef; 
					}
				}
=cut # 9/21

				foreach (0..$#years) {
					if ( $val_baseYear ) { # ��N�̒l�����݂���ꍇ
						$indicator_change_rate_baseYear[$_] = $indicator_change_rate[$_] / $val_baseYear;
						# @indicator_change_rate_baseYear = map { $_ /  $val_baseYear } @indicator_change_rate; 	# 9/15 �ύX
						$indicator_change_rate_baseYear{$years[$_]}{$region} = $indicator_change_rate_baseYear[$_]; 	# �o�͗p�n�b�V��
					} else {
						$indicator_change_rate_baseYear[$_] = undef; 
						# @indicator_change_rate_baseYear = map { $_ = undef; $_ } @indicator_change_rate; 	# 9/15 �ύX
					}
					if ($indicator[$_-1]) { 	# �O��(t-1)�̒l�����݂���ꍇ
						$indicator_change_rate_priorYear[$_] = $indicator_change_rate[$_] / $indicator[$_-1];
					} else {
						$indicator_change_rate_priorYear[$_] = undef; 
					}
				}

				print "\@indicator_change_rate : @indicator_change_rate \n"; 	# �m�F�p�o��
				print "\@indicator_change_rate_baseYear : @indicator_change_rate_baseYear \n"; 	# �m�F�p�o��
				print "\@indicator_change_rate_priorYear : @indicator_change_rate_priorYear \n"; 	# �m�F�p�o��

				# @indicator_change_rate�̃n�b�V����


				# �O���t�� @indicator �\���p�̃f�[�^��n��
				$title = $variables_for_Indicator[0];	# �w�W��
				$title =~ s/\=//ig;	# �u������ = ���폜
				print "\$title : $title\n"; 	# �m�F�p�o��
				$title_char[3] = $title;	# �O���t�ɕ\������ϐ���
				$title_char[4] = $unit_var1.$variables_for_Indicator[2].$unit_var2;	# �w�W�̒P�ʁ@[2]<-�����̈ʒu���w��
				print "\$title_char[4] : $title_char[4]\n"; 	# �m�F�p�o��
				$title_char[5] = join(' ', @variables_for_Indicator);	# �O���t�ɕ\������
				&graph(\@years, \@indicator, \@title_char); 	# graph @indicator

				# �O���t�� @indicator_change_rate �\���p�̃f�[�^��n��
				$title_char[3] = "ChangeRate_".$title;	# �O���t�ɕ\������ϐ���	#��ŒP�ʂ��������邱��
				&graph(\@years, \@indicator_change_rate, \@title_char); 	# graph 

				# �O���t�� @indicator_change_rate �\���p�̃f�[�^��n��
				$title_char[3] = "ChangeRate(b)_".$title;	# �O���t�ɕ\������ϐ���	#��ŒP�ʂ��������邱��
				&graph(\@years, \@indicator_change_rate_baseYear, \@title_char); 	# graph 

				# �O���t�� @indicator_change_rate �\���p�̃f�[�^��n��
				$title_char[3] = "ChangeRate(t)_".$title;	# �O���t�ɕ\������ϐ���	#��ŒP�ʂ��������邱��
				&graph(\@years, \@indicator_change_rate_priorYear, \@title_char); 	# graph 

			} 
			# @indicator�����������܂Ł�

		} 	# �ϐ���loop
	} 	# �n���loop


	#==========================
	# �uIAMCTemplate�v�`���t�@�C���̏o�́icsv�j
	#==========================

	open (OUT, ">>../$result_derectory/../../$file_output") or die "Can't open: $file_output: $!";	# �w��`���̏o��
	print "�yIAMCTemplate �`���t�@�C���̏o�́z\n"; 	# �m�F�p�o��

	my ($title_line, $year);
	foreach $title_line(@title_line) { print OUT "\"$title_line\","; }	# �^�C�g���s�̓t�@�C�����ɏo�͂��Ă���
	foreach $year(@years) { print OUT "\"$year\","; }	# ��t�@�C���Ԃ� year �̈�v��O��Ƃ��Ȃ�
	print OUT "\n"; 

	$title_char[3] = $title;	# �w�W��
	foreach $region(@regions) { 

		$title_char[2] = $region;	# �n��
		foreach (0..4) { print OUT "\"$title_char[$_]\","; }		# ������f�[�^�̏o��

		foreach $year(@years) { 
			print OUT "$indicator{$year}{$region},"; 	# �w�W�f�[�^�̏o��
			print "\%indicator {$year} {$region} : $indicator{$year}{$region}\n"; 	# �m�F�p�o��
		}
		print OUT "\n"; 
	} 	# loop by $region 


	$title_char[3] = "ChangeRate_".$title;	# �w�W��
	$title_char[4] = $title_char[4]."/y"; 	# �P��
	foreach $region(@regions) { 

		$title_char[2] = $region;	# �n��
		foreach (0..4) { print OUT "\"$title_char[$_]\","; }		# ������f�[�^�̏o��

		foreach $year(@years) { 
			print OUT "$indicator_change_rate_baseYear{$year}{$region},";  	# �ω����f�[�^�̏o�́A��N
			print "\$indicator_change_rate_baseYear {$year} {$region} : $indicator_change_rate_baseYear{$year}{$region}\n"; 
		}
		print OUT "\n"; 

	} 	# loop by $region 
	print OUT "\n"; 
	close(OUT);
	# �uIAMCTemplate�v�`���t�@�C���̏o�́icsv�j�������܂Ł�
}
# �V�i���I��loop
chdir "./..";


#=============
# Graph ����
#=============
sub graph { 

	my ($labels, $dataset1, $title_char ) = @_; 	# �z��̃��t�@�����X��ϐ��ň�U�󂯂�
#	my ($labels, $dataset1, $dataset2, $title_char ) = @_; 	# 2�ϐ��̂Ƃ�

	my @labels = @$labels; 	# �f���t�@�����X
	my @dataset1 = @$dataset1; 	# �f���t�@�����X
#	my @dataset2 = @$dataset2; 	# �f���t�@�����X 	# 2�ϐ��̂Ƃ�
	my @title_char = @$title_char; 	# �f���t�@�����X

	print "\n�yGraph�z\n"; 	# �m�F�p�o��
#	print "\@labels : @labels \n"; 	# �m�F�p�o��
#	print "\@dataset1 : @dataset1 \n"; 	# �m�F�p�o��
#	print "\@dataset2 : @dataset2 \n"; 	# �m�F�p�o�� 	# 2�ϐ��̂Ƃ�
#	print "\@title_char : @title_char \n"; 	# �m�F�p�o��

	my $MODEL	 = $title_char[0]; 	# ���w��
	my $SCENARIO = $title_char[1]; 
	my $REGION	 = $title_char[2]; 
	my $VARIABLE = $title_char[3]; 
	my $UNIT	 = $title_char[4]; 
	my $LEGEND	 = $title_char[5]; 

		# GD::Graph����	
		my @data    = ( \@labels, \@dataset1 );
#		my @data    = ( \@labels, \@dataset1, \@dataset2); 	# 2�ϐ��̂Ƃ�
#		my $graph = GD::Graph::linespoints->new(400, 400);
		my $graph = GD::Graph::points->new(400, 400);

		$graph->set( 
			x_label           => 'Year',
			y_label           => "$VARIABLE ($UNIT)",
			title             => "$VARIABLE | $SCENARIO | $REGION",
		#	x_label_skip      => 20, 	# 5�N�Ԋu�ɂ����ۂɓ���
		#	y_max_value       => 8, 
			y_tick_number     => 10
		#	y_label_skip      => 10 
		) or die $graph->error;

		$graph->set( x_label_skip => 20 ) or die $graph->error if ( $StepYear < 5 ); 	# X���x���̊Ԉ���


		$graph->set_legend("$LEGEND") if ( $LEGEND ); 	# 1�ϐ��̂Ƃ�
#		$graph->set_legend('Scenario', 'Reference'); 	# 2�ϐ��̂Ƃ�
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

		print "($VARIABLE)\_$SCENARIO\_$REGION.gif Completed! \n\n"; 	# �m�F�p�o��

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
# eachyear �i���N�u����s�K���ȊԊu�̐����1�N�Ԋu�ɕύX����j
#=============
sub eachyear { 

	my ($yearsRef, $varRef ) = @_; 	# �z��̃��t�@�����X��ϐ��ň�U�󂯂�

	my @years = @$yearsRef; 	# �f���t�@�����X
	my @var = @$varRef; 	# �f���t�@�����X

	# �O���t�p�n�b�V���i�N���L�[�Ƃ��Ēl��Ԃ��j�̍쐬
	my %varHash = map { $years[$_] => $var[$_] } (0..$#years); # �ϊ��p�n�b�V���ƔN�L�[�A$varhash{$year}
#	foreach (0..$#years) { print "(2)\t\$varHash{$years[$_]} : $varHash{$years[$_]} \n"; }

	my @years_sort = uniq(sort(@years)); 	# �d��, SKIP�΍�
	my $years_min = $years_sort[0]; 	# 
	my $years_max = $years_sort[$#years_sort]; 	# 

	my (@eachyear, @var_eachyear, $t, $dt, $pre_year, $post_year) = undef;
	for ( $t=0; $t<=$years_max-$years_min ; $t++ ) { 
		$eachyear[$t] = $years_min + $t;
		if ( $varHash{$eachyear[$t]} ) { 
			$var_eachyear[$t] = $varHash{$eachyear[$t]}; 
		} else {
			$var_eachyear[$t] = undef; 	# �l�̂Ȃ��N������` �Ƃ���ꍇ
		}
#		print "\$t:$t \t \$eachyear[$t]:$eachyear[$t] \t \$var_eachyear[$t]:$var_eachyear[$t]  \n"; 	# �m�F�p�o�� 
	}

	# ��Ԕz��	# �i�c��ۑ� @var_eachyear=0 �̏ꍇ�j	# ����
	foreach $t(0..$#eachyear) { 	# �z��ԍ��ɂ��loop�i1����n�߂�̂́A0�̏ꍇ�͑O���̒l���������߁j
		$pre_year = $eachyear[$t] if ($var_eachyear[$t]); 
		if ( $var_eachyear[$t] eq undef ) {
			$post_year = undef; 
			foreach $dt($t..$#eachyear) { 	# �z��ԍ��ɂ��loop
				if ( $var_eachyear[$dt] ) { 
					$post_year = $eachyear[$dt]; 
#					print "\$t:$t \t \$dt:$dt \t \$pre_year:$pre_year \t \$post_year:$post_year \n"; 	# �m�F�p�o��
					last; 
				}
			}

		}
	}
	# ��Ԕz��	# ����
	# ��񂵁� ( $var_eachyear[$t] == undef ) �̏ꍇ�̕�ԏ���

	my @eachyearReturn = (\@eachyear, \@var_eachyear); 	# 2�z��̃��t�@�����X��Ԃ�
	return @eachyearReturn;
} 	# eachyear �I��

#=============
# Close ����
#=============
# close(STDOUT);

__END__
:endofperl


:endofperl

