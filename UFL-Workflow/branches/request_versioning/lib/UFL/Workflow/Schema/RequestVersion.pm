package UFL::Workflow::Schema::RequestVersion;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Digest::MD5 ();
use MIME::Types ();
use Path::Class::File ();
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('requests_versions');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    request_id => {
        data_type => 'integer',
    },
    version => {
        data_type => 'integer',
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
   request => 'UFL::Workflow::Schema::Request',
   'request_id',
);

__PACKAGE__->has_many(
    documents => 'UFL::Workflow::Schema::Document',
    { 'foreign.request_version_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    field_data => 'UFL::Workflow::Schema::FieldData',
    { 'foreign.request_version_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->resultset_attributes({
    order_by => \q[me.version DESC, me.update_time DESC, me.insert_time DESC],
});

=head1 NAME

UFL::Workflow::Schema::Request - Request table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Request table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 first_field_data

Return the first L<UFL::Workflow::Schema::FieldData> entered for this
request, i.e., the earliest L<UFL::Workflow::Schema::FieldData> in the
L<UFL::Workflow::Schema::Request>.

=cut

sub first_field_data {
    my ($self) = @_;

    my $first_field = $self->process->first_field;
    if ($first_field) {
        my $first_field_data = $self->field_data->search({ 
            field_id           => $first_field->id,
            request_version_id => $self->id,
        })->first;

        return $first_field_data;
    }
}

=head2 get_field_data_by_id

Return the L<UFL::Workflow::Schema::FieldData> entered for this
request by field data id.

=cut

sub get_field_data_by_id {
    my ($self, $field_id) = @_;

    if ($field_id) {
        if( my $field_content = $self->get_all_field_data_by_id($field_id)) {
            return $field_content->first;
        }
    }
}

=head2 get_all_field_data_by_id

Return all versions of field data.

=cut
sub get_all_field_data_by_id {
    my ($self, $field_id) = @_;  
    
    if ($field_id) {
        my $field_datas = $self->field_data->search({ 
            field_id           => $field_id,
            request_version_id => $self->id,
        });
        return $field_datas;
    }
} 

=head2 create_field_data

Adds the field data to database.

=cut
sub create_field_data{
    my ($self, $field_id, $value) = @_;

    $self->result_source->schema->txn_do(sub {
         $self->field_data->create({
              request_version_id => $self->id,
              field_id           => $field_id,
              value              => $value,
         });
    });
}

=head2 add_field_data

Add a new field data to this request corresponding to the specified
L<UFL::Workflow::Schema::Field>.

=cut
sub add_field_data {
    my ($self, $result_field) = @_;

    if ( my %fields = $self->get_field_data($result_field)) {
        foreach my $field_id ( keys (%fields)) {
            $self->create_field_data( $field_id, $fields{$field_id} );
        }
     }
}

=head2 is_field_data_changed 

Will return true if a single bit is changed..

=cut
sub is_field_data_changed {
    my ($self, $result_field) = @_;
    
    if ( my %new_field_data = $self->get_field_data($result_field)) {
        foreach my $each_field_id ( keys (%new_field_data)) {
            if ( $self->get_field_data_by_id($each_field_id)->value ne $new_field_data{$each_field_id} ) {
                return 1;
            }
        }
     }
     return 0;
}

=head2 get_field_data 

retrieves the data from form content and stores in DB. 

=cut
sub get_field_data {
    my ($self, $result) = @_;

    my %data;
    my $field = $self->process->first_field;
    
    while ($field) {
        $data{$field->id} = $result->valid($field->id);
        $field = $field->next_field;
    }

    return %data;
}

=head2 validate_fields 

Validates the extra fields of this process

=cut
sub validate_field {
    my ($self, $c, $field_id) = @_;
    $c->stash( process => $self->process );
    return $self->process->validate_field($c, $self->get_field_data_by_id($field_id)->field);
}

=head2 validate_fields 

Validates the extra fields of this process

=cut
sub validate_fields {
    my ($self, $c) = @_;
    $c->stash( process => $self->process );
    return $self->process->validate_fields($c);
}
=head2 add_document

Add a new L<UFL::Workflow::Schema::Document> to this request.

=cut

sub add_document {
    my ($self, $user, $filename, $contents, $destination, $replaced_document_id) = @_;

    $self->throw_exception('You must provide a filename, the contents, and a destination directory')
        unless $filename and $contents and $destination;
    $self->throw_exception('You must provide a user')
        unless blessed $user and $user->isa('UFL::Workflow::Schema::User');
    $self->throw_exception('User cannot manage request')
        unless $user->can_manage($self);

    my ($name, $extension) = ($filename =~ /(.+)\.([^.]+)$/);
    $extension = lc $extension;

    my $type = MIME::Types->new->mimeTypeOf($extension);
    die "Unknown type for extension [$extension]" unless $type;

    my $document;
    $self->result_source->schema->txn_do(sub {
        my $length = $self->documents->result_source->column_info('name')->{size};

        $document = $self->documents->create({
            name      => substr($name, 0, $length),
            extension => $extension,
            type      => $type,
            md5       => Digest::MD5::md5_hex($contents),
        });

        if ($replaced_document_id) {
            my $replaced_document = $self->documents->find($replaced_document_id);
            die 'Replaced document not found' unless $replaced_document;

            $replaced_document->document_id($document->id);
            $replaced_document->update;
        }

        # Copy the file into the destination
        my $filename = Path::Class::File->new($destination, $document->path);
        $filename->parent->mkpath;
        my $fh = IO::File->new($filename, 'w') or die "Error opening $filename: $!";
        $fh->binmode(':raw');
        $fh->print($contents);
        $fh->close;
    });

    return $document;
}

=head2 process 

returns the process of this request

=cut

sub process{
    my ($self) = @_;

    return $self->request->process;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this request.

=cut

sub uri_args {
    my ($self) = @_;

    return [ $self->id ];
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
