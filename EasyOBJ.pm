
=head1 NAME

XML::EasyOBJ - Easy XML object navigation

=head1 VERSION

Version 1.10

=head1 SYNOPSIS

 # open exisiting file
 my $doc = new XML::EasyOBJ('my_xml_document.xml');
 my $doc = new XML::EasyOBJ(-type => 'file', -param => 'my_xml_document.xml');

 # create new file
 my $doc = new XML::EasyOBJ(-type => 'new', -param => 'root_tag');
 
 # read from document
 my $text = $doc->some_element($index)->getString;
 my $attr = $doc->some_element($index)->getAttr('foo');
 my $element = $doc->some_element($index);

 # first "some_element" element
 my $elements = $doc->some_element;
 # list of "some_element" elements
 my @elements = $doc->some_element;

 # write to document
 $doc->an_element->setString('some string')
 $doc->an_element->addString('some string')
 $doc->an_element->setAttr('attrname', 'val')

 # access elements with non-name chars and the underlying DOM
 my $element = $doc->getElement('foo-bar')->getElement('bar-none');
 my $dom = $doc->foobar->getDomObj;

 # remove elements/attrs
 $doc->remElement('tagname', $index);
 $doc->tag_name->remAttr($attr);

 # remap builtin methods
 $doc->remapMethod('getString', 's');
 my $text = $doc->some_element->s;


=head1 DESCRIPTION

I wrote XML::EasyOBJ a couple of years ago because it seemed to me
that the DOM wasn't very "perlish".  The DOM is difficult to us
mere mortals that don't use it on a regular basis.  As I only need
to process XML on an occasional basis I wanted an easy way to do what
I needed to do without having to refer back to DOM documentation and
UML class diagrams each time.

A quick fact list about XML::EasyOBJ:

 * Runs on top of XML::DOM
 * Allows access to the DOM as needed
 * Simple routines to reading and writing elements/attributes

=head1 REQUIREMENTS

XML::EasyOBJ uses XML::DOM.  XML::DOM is available from CPAN (www.cpan.org).

=head1 BEGINNER QUICK START GUIDE

=head2 Introduction

You too can write XML applications, just as long as you understand
the basics of XML (elements and attributes). You can learn to write
your first program that can read data from an XML file in a mere
10 minutes. 

=head2 Assumptions

It is assumed that you are familiar with the structure of the document that
you are reading.  Next, you must know the basics of perl lists, loops, and
how to call a function.  You must also have an XML document to read.

Simple eh?

=head2 Loading the XML document

 use XML::EasyOBJ;
 my $doc = new XML::EasyOBJ('my_xml_document.xml') || die "Can't make object";

Replace the string "my_xml_document.xml" with the name of your XML document.
If the document is in another directory you will need to specify the path
to it as well.

The variable $doc is an object, and represents our root XML element in the document.

=head2 Reading text with getString

Each element becomes an object. So lets assume that the XML page looks like
this:

 <table>
  <record>
   <rec2 foo="bar">
    <field1>field1a</field1>
    <field2>field2b</field2>
    <field3>field3c</field3>
   </rec2>
   <rec2 foo="baz">
    <field1>field1d</field1>
    <field2>field2e</field2>
    <field3>field3f</field3>
   </rec2>
  </record>
 </table>

As mentioned in he last step, the $doc object is the root
element of the XML page. In this case the root element is the "table"
element.

To read the text of any field is as easy as navigating the XML elements.
For example, lets say that we want to retrieve the text "field2e". This
text is in the "field2" element of the SECOND "rec2" element, which is
in the FIRST "record" element.

So the code to print that value it looks like this:

 print $doc->record(0)->rec2(1)->field2->getString;

The "getString" method returns the text within an element.

We can also break it down like this:

 # grab the FIRST "record" element (index starts at 0)
 my $record = $doc->record(0);
 
 # grab the SECOND "rec2" element within $record
 my $rec2 = $record->rec2(1);
 
 # grab the "field2" element from $rec2
 # NOTE: If you don't specify an index, the first item 
 #       is returned and in this case there is only 1.
 my $field2 = $rec2->field2;

 # print the text
 print $field2->getString;

=head2 Reading XML attributes with getAttr

Looking at the example in the previous step, can you guess what
this code will print?

 print $doc->record(0)->rec2(0)->getAttr('foo');
 print $doc->record(0)->rec2(1)->getAttr('foo');

If you couldn't guess, they will print out the value of the "foo"
attribute of the first and second rec2 elements. 

=head2 Looping through elements

Lets take our example in the previous step where we printed the
attribute values and rewrite it to use a loop. This will allow
it to print all of the "foo" attributes no matter how many "rec2"
elements we have.

 foreach my $rec2 ( $doc->record(0)->rec2 ) {
   print $rec2->getAttr('foo');
 }

When we call $doc->record(0)->rec2 this way (i.e. in list context), 
the module will return a list of "rec2" elements.

=head2 That's it!

You are now an XML programmer! *start rejoicing now*

=head1 PROGRAMMING NOTES

When creating a new instance of XML::EasyOBJ it will return an
object reference on success, or undef on failure. Besides that,
ALL methods will always return a value. This means that if you
specify an element that does not exist, it will still return an
object reference (and create that element automagically). This 
is just another way to lower the bar, and make this module easier 
to use.

You will run into problems if you have XML tags which are named
after perl's special subroutine names (i.e. "DESTROY", "AUTOLOAD"), 
or if they are named after subroutines used in the module 
( "getString", "getAttr", etc ). You can get around this by using
the getElement() method of using the remapMethod() method which can
be used on every object method (except AUTOLOAD and DESTROY).

=head1 AUTHOR/COPYRIGHT

Copyright (C) 2000-2002 Robert Hanson <rhanson@blast.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

XML::DOM

=cut

package XML::EasyOBJ;

use strict;
use XML::DOM;
use vars qw/$VERSION/;

$VERSION = '1.10';

sub new {
	my $class = shift;
	my $doc = '';
	my $expref = 0;
	
	if ( scalar(@_) % 2 ) {
		my $file = shift;
		my $parser = new XML::DOM::Parser;
		$doc = $parser->parsefile( $file ) || return;
	}
	else {
		my %args = @_;

		$expref = 1 if ( exists $args{-expref} and $args{-expref} == 1 );
				
		if ( $args{-type} eq 'file' ) {
			my $parser = new XML::DOM::Parser;
			$doc = $parser->parsefile( $args{-param} ) || return;
		}
		elsif ( $args{-type} eq 'new' ) {
			$doc = new XML::DOM::Document();
			$doc->appendChild( $doc->createElement( $args{-param} ) );
		}
		else {
			return;
		}
	}

	my %map = ();
	$map{getString}   = 'getString';
	$map{setString}   = 'setString';
	$map{addString}   = 'addString';
	$map{getAttr}     = 'getAttr';
	$map{setAttr}     = 'setAttr';
	$map{remAttr}     = 'remAttr';
	$map{remElement}  = 'remElement';
	$map{getElement}  = 'getElement';
	$map{getDomObj}   = 'getDomObj';
	$map{remapMethod} = 'remapMethod';

	return bless( 
		{	'map' => \%map,
			'doc' => $doc,
			'ptr' => $doc->getDocumentElement(),
			'expref' => $expref,
		}, 'XML::EasyOBJ::Object' );
}

package XML::EasyOBJ::Object;

use strict;
use XML::DOM;
use vars qw/%SUBLIST %INTSUBLIST $AUTOLOAD/;

$AUTOLOAD = '';
%SUBLIST = ();
%INTSUBLIST = ();

sub DESTROY {
	local $^W = 0;
	my $self = $_[0];
	$_[0] = '';
	unless ( $_[0] ) {
		$_[0] = $self;
		$AUTOLOAD = 'DESTROY';
		return AUTOLOAD( @_ );
	}
}

sub AUTOLOAD {
	my $funcname = $AUTOLOAD || 'AUTOLOAD';
	$funcname =~ s/^XML::EasyOBJ::Object:://;
	$AUTOLOAD = '';

	if ( exists $_[0]->{map}->{$funcname} ) {
		return &{$SUBLIST{$_[0]->{map}->{$funcname}}}( @_ );
	}

	my $self = shift;
	my $index = shift;
	my @nodes = ();

	die "Fatal error: lost pointer!" unless ( exists $self->{ptr} );

	for my $kid ( $self->{ptr}->getChildNodes ) {
		if ( ( $kid->getNodeType == ELEMENT_NODE ) && ( $kid->getTagName eq $funcname ) ) {
			push @nodes, bless( 
				{	map => $self->{map}, 
					doc => $self->{doc}, 
					ptr => $kid,
					expref => $self->{expref},
				}, 'XML::EasyOBJ::Object' );
		}
	}

	if ( wantarray ) {
		return @nodes;
	}
	else {
		if ( defined $index ) {
			unless ( defined $nodes[$index] ) {
				for ( my $i = scalar(@nodes); $i <= $index; $i++ ) {
					$nodes[$i] = bless(
						{ 	map => $self->{map}, 
							doc => $self->{doc}, 
							ptr => &{$INTSUBLIST{'makeNewNode'}}( $self, $funcname ),
							expref => $self->{expref},
						}, 'XML::EasyOBJ::Object' )
				} 
			}
			return $nodes[$index];
		}
		else {
			return bless( 
				{ 	map => $self->{map}, 
					doc => $self->{doc}, 
					ptr => &{$INTSUBLIST{'makeNewNode'}}( $self, $funcname ),
					expref => $self->{expref},
				}, 'XML::EasyOBJ::Object' ) unless ( defined $nodes[0] );
			return $nodes[0];
		}
	}
}


$INTSUBLIST{'makeNewNode'} =
	sub {
		my $self = shift;
		my $funcname = shift;
		return $self->{ptr}->appendChild( $self->{doc}->createElement($funcname) );
	};

$INTSUBLIST{extractText} =
	sub {
		my $n = shift;
		my $text;

		if ( $n->getNodeType == TEXT_NODE ) {
			$text = $n->toString;
		}
		elsif ( $n->getNodeType == ELEMENT_NODE ) {
			foreach my $c ( $n->getChildNodes ) {
				$text .= &{$INTSUBLIST{extractText}}( $c );
			}
		}
		return $text;
	};

$SUBLIST{remapMethod} =
	sub {
		my $self = shift;
		my ( $from, $to ) = @_;
		
		die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );
		
		return unless ( ( $from ) && ( $to ) );
		return unless ( exists $self->{map}->{$from} );
		
		my $tmp = $self->{map}->{$from};
		delete $self->{map}->{$from};
		$self->{map}->{$to} = $tmp;
		return 1;
	};

$SUBLIST{getString} =
	sub {
		my $self = shift;
		die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );
		my $string = &{$INTSUBLIST{extractText}}( $self->{ptr} );
		return ( $self->{expref} ) ? $self->{doc}->expandEntityRefs($string) : $string;
	};

$SUBLIST{setString} = 
	sub {
		my $self = shift;
		my $text = shift;
	
		die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );
	
		foreach my $n ( $self->{ptr}->getChildNodes ) {
			if ( $n->getNodeType == TEXT_NODE ) {
				$self->{ptr}->removeChild( $n );
			}
		}
	
		$self->{ptr}->appendChild( $self->{doc}->createTextNode( $text ) );
		return &{$INTSUBLIST{extractText}}( $self->{ptr} );
	};

$SUBLIST{addString} =
	sub {
		my $self = shift;
		my $text = shift;
	
		die "Fatal error: lost the pointer!" unless ( exists $self->{ptr} );
	
		$self->{ptr}->appendChild( $self->{doc}->createTextNode( $text ) );
		return &{$INTSUBLIST{extractText}}( $self->{ptr} );
	};

$SUBLIST{getAttr} = 
	sub {
		my $self = shift;
		my $attr = shift;
	
		die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );
		if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
			return $self->{ptr}->getAttribute($attr);
		}
		return '';
	};

$SUBLIST{setAttr} =
	sub {
		my $self = shift;
		my $attr = shift;
		my $text = shift;
	
		die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );
		if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
			return $self->{ptr}->setAttribute($attr, $text);
		}
		return '';
	};

$SUBLIST{remAttr} = 
	sub {
		my $self = shift;
		my $attr = shift;
	
		die "Fatal error: lost the pointer!" unless( exists $self->{ptr} );
		if ( $self->{ptr}->getNodeType == ELEMENT_NODE ) {
			if ( $self->{ptr}->getAttributes->getNamedItem( $attr ) ) {
				$self->{ptr}->getAttributes->removeNamedItem( $attr );
				return 1;
			}
		}
		return 0;
	};

$SUBLIST{remElement} = 
	sub {
		my $self = shift;
		my $name = shift;
		my $index = shift;

		my $node = ( $index ) ? $self->$name($index) : $self->$name();
		$self->{ptr}->removeChild( $node->{ptr} );
	};

$SUBLIST{getElement} = 
	sub {
		my $self = shift;
		my $funcname = shift;
		my $index = shift;
		my @nodes = ();

		die "Fatal error: lost pointer!" unless ( exists $self->{ptr} );

		for my $kid ( $self->{ptr}->getChildNodes ) {
			if ( ( $kid->getNodeType == ELEMENT_NODE ) && ( $kid->getTagName eq $funcname ) ) {
				push @nodes, bless( 
					{	map => $self->{map}, 
						doc => $self->{doc}, 
						ptr => $kid,
						expref => $self->{expref},
					}, 'XML::EasyOBJ::Object' );
			}
		}

		if ( wantarray ) {
			return @nodes;
		}
		else {
			if ( defined $index ) {
				unless ( defined $nodes[$index] ) {
					for ( my $i = scalar(@nodes); $i <= $index; $i++ ) {
						$nodes[$i] = bless(
							{ 	map => $self->{map}, 
								doc => $self->{doc}, 
								ptr => &{$INTSUBLIST{'makeNewNode'}}( $self, $funcname ),
								expref => $self->{expref},
							}, 'XML::EasyOBJ::Object' )
					} 
				}
				return $nodes[$index];
			}
			else {
				return bless( 
					{ 	map => $self->{map}, 
						doc => $self->{doc}, 
						ptr => &{$INTSUBLIST{'makeNewNode'}}( $self, $funcname ),
						expref => $self->{expref},
					}, 'XML::EasyOBJ::Object' ) unless ( defined $nodes[0] );
				return $nodes[0];
			}
		}
	};

$SUBLIST{getDomObj} = 
	sub {
		my $self = shift;
		return $self->{ptr};
	};

1;


