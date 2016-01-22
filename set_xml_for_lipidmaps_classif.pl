#! perl

use strict ;
no strict "refs" ;
use warnings ;
use Carp qw (cluck croak carp) ;

use Data::Dumper ;
use XML::Twig;
use Getopt::Long ;

use XML::Writer;
use IO::File;

## Initialized values
my ( $OptHelp, $OptTaxFile, $OptLevels, $OptOutput ) = (undef, 'E:\\TESTs\\lipidmaps\\2013_lm_classif.txt' ,3, 'E:\\TESTs\\lipidmaps\\2013_lm_classif_conf.xml' ) ;
#my ( $OptHelp, $OptTaxFile, $OptLevels, $OptOutput ) = (undef, undef, undef, undef ) ;


&GetOptions ( 	"help|h"     		=> \$OptHelp,       # HELP
				"tax:s"		=> \$OptTaxFile, ## option : path to the taxonomy file
				"levels:i"	=> \$OptLevels, ## option : level 1 = create the category level | level 2 = create category and class levels | level 3 = create cat/class and subclass levels
				"output|o:s"=> \$OptOutput, ## Output file containing tags for galaxy xml file
            ) ;

#=============================================================================
#                                EXCEPTIONS
#=============================================================================
$OptHelp and &Help ;

## Conf file
# N/A

my %Taxonomy = () ;
my $i = 0 ; # nb of categories
my $test_ifclasse = 0 ; # play if a class exist 
my $current_cat = undef ;
my $current_cl = undef ;
my @Classes = () ;

my ( @cat, @cl, @subcl ) = ( (), (), () ) ; ## 

## Existence des parametres d'entrées :
if ( ( defined $OptTaxFile ) and ( defined $OptLevels ) ) {
	
	if (-e $OptTaxFile ) {
		open (TAX, "<$OptTaxFile") or die "Can't open $OptTaxFile\n" ;
		while (<TAX>) {
			chomp $_ ;
			
			## Parsing steps
			if ( ( $OptLevels == 1 ) or ( $OptLevels > 1 ) ) {
				my $new_cat = &catch_categories($_) ;
				if (defined $$new_cat) { push ( @cat, $new_cat ) ; } 
			}
			if ( ( $OptLevels == 2 ) or ( $OptLevels > 2 ) ) {
				my $new_cl = &catch_classes($_) ;
				if (defined $$new_cl) { push ( @cl, $new_cl ) ; }
			}
			if ( $OptLevels == 3 ) {
				my $new_subcl = &catch_subclasses($_) ;
				if (defined $$new_subcl) { push ( @subcl, $new_subcl ) ; }
			}
		} ## end of while
#		print "===> CAT :\n";
#		print Dumper @cat ;
#		print "\n===> CLASSES :\n";
#		print Dumper @cl ;
#		print "\n===> SUBCLASSES :\n";
#		print Dumper @subcl ;
		
		close (TAX) ;
		
		&write_xml_conf( $OptOutput, \@cat, \@cl, \@subcl ) ;
		
		if (-e $OptOutput ) {
			print "End of Generation : please open the file $OptOutput and copy paste content\n" ;
		}
	}
	else {
		croak "No taxonomy file is available in $OptTaxFile\n" ;
	}
}
else {
	&Help ;
	croak "Some Parameters are not defined (-tax and -levels )\n" ;
}


## Fonction : catch any entry formatting like a category. Ex: category_name [XX]
## Input : $entry, list of already found categories
## Ouput : list of updated categories
sub catch_categories {
    ## Retrieve Values
    my ( $entry ) = @_;
    my @cats = undef ;
    my $new_cat = undef ;
    
    if ( defined $entry ) {
    	if ( $entry  =~ /([\s|\w]+)\s+\[([A-Z]+)\]/ ) { ## ex: Glycerolipids [GL]
    		$new_cat = $entry ;
    	}
    }
    else {
    	croak "Can't parse any entry for catching any category\n" ;
    }
    return(\$new_cat) ;
}
### END of SUB

## Fonction : catch any entry formatting like a class. Ex: class_name [XXnn]
## Input : $entry, list of already found classes
## Ouput : list of updated classes
sub catch_classes {
    ## Retrieve Values
    my ( $entry, $cl_ref ) = @_;
    my $new_cl = undef ;
    
    if ( defined $entry ) {
    	if ( $entry  =~ /(.*)\s+\[(\w{2})(\d{2})\]/ ) { ## ex: Diradylglycerols [GL02]
    		$new_cl = $entry ;
    	}
    }
    else {
    	croak "Can't parse any entry for catching any class\n" ;
    }
    return(\$new_cl) ;
}
### END of SUB

## Fonction : catch any entry formatting like a subclass. Ex: subclass_name [XXnnnn]
## Input : $entry, list of already found subclasses
## Ouput : list of updated subclasses
sub catch_subclasses {
    ## Retrieve Values
    my ( $entry, $subcl_ref ) = @_;
    my $new_subcl = undef ;
    
    if ( defined $entry ) {
    	if ( $entry  =~ /(.*)\s+\[(\w{2})(\d{4})\]/ ) { ## ex: 1-acyl,2-alkylglycerols [GL0207]
    		$new_subcl = $entry ;
    	}
    }
    else {
    	croak "Can't parse any entry for catching any subclass\n" ;
    }
    return(\$new_subcl) ;
}
### END of SUB

## Fonction :
## Input :
## Ouput :
sub write_xml_conf {
    ## Retrieve Values
    my ( $output, $cats, $cls, $subcls ) = @_;
    
    my ( @cat_ids, @cl_ids ) = ( (), () ) ;
    
    my $xml = new IO::File(">$output");
	my $writer = new XML::Writer( 
	    OUTPUT      => $xml,
	    DATA_INDENT => 3,             # indentation, trois espaces
	    DATA_MODE   => 1,             # changement ligne.
	    ENCODING    => 'utf-8',
	);
	
	$writer->xmlDecl("UTF-8");
	$writer->startTag("conditional", "name" => "select_cat" );
	
		## START CAT PART --------------------------------------
		$writer->startTag("param", "name" => "filter_cat", "label" => "Select a Lipid category for your query ", "type" => "select" );
		
		if ( scalar @{$cats} > 0 ) {
			my $nb_cat = 0 ;
			
			## FOREACH CAT
			foreach my $cat ( @{$cats} ) {
				if ( $$cat =~ /(.*)\[([A-Z]+)\]/) {
					$i++ ;
					push( @cat_ids, $2 ) ;
					$writer->startTag("option", "value" => $i ) ;
					$writer->characters($$cat);
					$writer->endTag("option");
				}
			} ## end foreach cat
		}
		else {
			carp "The ref cat list is empty\n" ;
		}
		$writer->endTag("param");
		## END CAT PART ----------------------------------------

		## START CLASSES PART ----------------------------------
		if ( scalar @{$cls} > 0 ) {
			my $nb_cat = 0 ;
			foreach my $cat_id ( @cat_ids ) {
				$nb_cat++ ;
				@cl_ids = () ;
				$writer->startTag("when", "value" => $nb_cat ) ;
					$writer->startTag("conditional", "name" => "select_cat" );
						$writer->startTag("param", "name" => "filter_class", "label" => "Select a Lipid main class for your query ", "type" => "select" );
						## FOREACH CLASSE
						foreach my $cl ( @{$cls} ) {
							if ( $$cl =~ /(.*)\[$cat_id(\d{2})\]/) {
								push (@cl_ids, $2) ;
								$writer->startTag("option", "value" => $nb_cat.$2 ) ;
								$writer->characters($$cl);
								$writer->endTag("option");
							}
						}
						## add the possibility of No used class
						$writer->startTag("option", "value" => "NA_".$nb_cat, "selected" => "True" ) ;
						$writer->characters("No main class selected");
						$writer->endTag("option");
						
						$writer->endTag("param");
						## START SUBCLASSES
						if ( scalar @{$subcls} > 0 ) {
							foreach my $cl_id ( @cl_ids ) {
								$writer->startTag("when", "value" => $nb_cat.$cl_id ) ;
									$writer->startTag("conditional", "name" => "select_subclass" ) ;
										$writer->startTag("param", "name" => "filter_subclass", "label" => "Select a Lipid subclass for your query ", "type" => "select" );
										## FOREACH CLASSE
										my $sub_cl_test = 0 ;
										foreach my $subcl ( @{$subcls} ) {
											if ( $$subcl =~ /(.*)\[$cat_id$cl_id(\d{2})\]/) {
												$sub_cl_test = 1 ;
												$writer->startTag("option", "value" => $nb_cat.$cl_id.$2 ) ;
												$writer->characters($$subcl);
												$writer->endTag("option");
											}
										}
										## if subclasses exists 										
										if ( $sub_cl_test == 0 ) {
											$writer->startTag("option", "value" => "NA_".$nb_cat.$cl_id ) ;
											$writer->characters("No subclass available");
											$writer->endTag("option");
										}
										else {
											## add the possibility of No used class
											$writer->startTag("option", "value" => "NA_".$nb_cat.$cl_id, "selected" => "True" ) ;
											$writer->characters("No subclass selected");
											$writer->endTag("option");
										}
										
										$writer->endTag("param");
									$writer->endTag("conditional") ;
								$writer->endTag("when") ;	
							} ## end foreach id
						}
						## END SUBCLASSES
					$writer->endTag("conditional") ;
				$writer->endTag("when") ;
			} ## end foreach id
		}
		## END CLASSES PART ----------------------------------------
	$writer->endTag("conditional") ;
    
    return() ;
}
### END of SUB





#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub Help {
	print STDERR "
createLipidmapsTax

# createLipidmapsTax is a script to process lipidmpas taxonomy file and return a list of xml tags for Galaxy web interface.
# Input : a file (TXT format)
# Author : Franck Giacomoni
# Email : fgiacomoni\@clermont.inra.fr
# Version : 1.0
# Created : 29/10/2012
USAGE :		 
		createLipidmapsTax.pl -tax [path to input txt file] -levels [1|2|3] (1 for categories only, 2 for categories+classes and 3 for categories+classes+subclasses)
		or createLipidmapsTax.pl -help
		";
	exit(1);
}

## END of script - F Giacomoni