
=head1 NAME

XML::EasyOBJ - Easy XML object navigation

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

 # create the object
 my $doc = new XML::EasyOBJ('my_xml_document.xml');

 # print some text from the document
 print $doc->some_element(1)->getString;

 # print an attribute value
 print $doc->some_element(0)->getAttr('foo')."\n";

 # iterate over a list of elements
 foreach my $x ( $foo->some_element ) {
   print $x->getString."\n";
   }

=head1 DESCRIPTION

XML::EasyOBJ lets you take an XML page and essentially create an object
out of it.  Each element becomes a method, which makes it really easy
to navigate an XML page (if you know the structure).  The motivation 
behind this module was to create an interface so simple that anyone who 
knows the basic functionality of Perl can learn how to read data from 
an XML document in less than 10 minutes (well, that and the fact that 
my modules haven't been mentioned in TPJ yet, and maybe this one will :).

This module is also a time saver even if you are familiar with the other
modules available, but want something simple so that you can throw
together a script in a few minutes (unless of course you know the DOM like
the back of your hand).

=head1 REQUIREMENTS

XML::EasyOBJ uses XML::DOM.  XML::DOM is available from CPAN (www.cpan.org).

=head1 QUICK START GUIDE

=head2 Introduction

Even if you have never used any XML module, just as long as you understand
the basics of XML (elements and attributes), you can learn to write a
program that can read data from an XML file in 10 minutes. ...Well maybe
30 minutes if you are a slow reader like I am.

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

 $doc->record(0)->rec2(0)->getAttr('foo');
 $doc->record(0)->rec2(1)->getAttr('foo');

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

When we call $doc->record(0)->rec2 this way, the module will
return a list of "rec2" elements.

=head2 That's it!

You are now an XML programmer! *start rejoicing now*

=head1 PROGRAMMING NOTES

When creating a new instance of XML::EasyOBJ it will return an
object reference on success, or undef on failure. Besides that,
ALL methods will always return a value. This means that if you
specify an element that does not exist, it will still return an
object reference. This is just another way to lower the bar, and
make this module easier to use.

You will run into problems if you have XML tags which are named
after perl's special subroutine names (ie "DESTROY", "AUTOLOAD"), or if they
are named after subroutines used in the module ( "getString", "getAttr",
"_extractText", and "new" ).

=head1 AUTHOR/COPYRIGHT

Robert Hanson (rhanson@blast.net)

Copyright 2000, Robert Hanson. All rights reserved. 

This library is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself. 

=head1 SEE ALSO

XML::DOM

=cut

package XML::EasyOBJ;

use strict;
use XML::DOM;
use vars qw/$AUTOLOAD $VERSION/;

$VERSION = '1.0';

sub new
	{
	my $class = shift;
	my $file = shift;
	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile( $file ) || return;
	return bless( { 'ptr' => $doc->getDocumentElement() }, $class );
	}

sub AUTOLOAD
	{
	my $self = shift;
	my $index = shift;
	my @nodes;

	my $funcname = $AUTOLOAD;
	$funcname =~ s/^XML::EasyOBJ:://;

	return bless( {}, 'XML::EasyOBJ' ) unless ( exists $self->{ptr} );
	return bless( {}, 'XML::EasyOBJ' ) unless ( $self->{ptr}->hasChildNodes );
	for my $kid ( $self->{ptr}->getChildNodes )
		{
		if ( ( $kid->getNodeType == ELEMENT_NODE ) && ( $kid->getTagName eq $funcname ) )
			{
			push @nodes, bless( { ptr => $kid }, 'XML::EasyOBJ' );
			}
		}
	return unless @nodes;
	if ( wantarray )
		{
		return @nodes;
		}
	else
		{
		if ( defined $index )
			{
			return bless( {}, 'XML::EasyOBJ' ) unless ( defined $nodes[$index] );
			return $nodes[$index];
			}
		else
			{
			return bless( {}, 'XML::EasyOBJ' ) unless ( defined $nodes[0] );
			return $nodes[0];
			}
		}
	}


sub DESTROY
	{
	}


sub getString
	{
	my $self = shift;
	return '' unless ( exists $self->{ptr} );
	return _extractText( $self->{ptr} );
	}

sub getAttr
	{
	my $self = shift;
	my $attr = shift;
	
	return '' unless( exists $self->{ptr} );
	if ( $self->{ptr}->getNodeType == ELEMENT_NODE )
		{
		return $self->{ptr}->getAttribute($attr);
		}
	return '';
	}


sub _extractText
	{
	my $n = shift;
	my $text;

	if ( $n->getNodeType == TEXT_NODE )
		{
		$text = $n->toString;
		}
	elsif ( $n->getNodeType == ELEMENT_NODE )
		{
		foreach my $c ( $n->getChildNodes )
			{
			$text .= _extractText( $c );
			}
		}
	return $text;
	}

1;
