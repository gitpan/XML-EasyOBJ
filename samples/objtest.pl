use XML::EasyOBJ;

my $doc = new XML::EasyOBJ('rax02test.xml') || die;

# grab the SECOND "record" element (index starts at 0)
my $record = $doc->record(1);

# grab the FIRST "rec2" element within $record
my $rec2 = $record->rec2(0);

# grab the "field2" element from $rec2
# NOTE: If you don't specify an index, the first is returned
#       and in this case there is only 1.
my $field2 = $rec2->field2;

# print the text
print $field2->getString;


exit;

