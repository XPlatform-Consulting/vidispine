# Vidispine


## Installation

Execute the following:

    $ git clone https://github.com/XPlatform-Consulting/vidispine.git
    $ cd vidispine
    $ bundle

Or install it yourself using the specific_install gem:

    $ gem install specific_install
    $ gem specific_install https://github.com/XPlatform-Consulting/vidispine.git

## Vidispine API Executable [bin/vidispine](../bin/vidispine)

### Usage

    Usage:
        vidispine -h | --help
        vidispine --method-name <method name> --method-arguments <method arguments>

    Options:
            --host-address HOSTADDRESS   The address of the server to communicate with.
                                          default: localhost
            --host-port HOSTPORT         The port to use when communicating with the server.
                                          default: 8080
            --username USERNAME          The account username to authenticate with.
            --password PASSWORD          The account password to authenticate with.
            --accepts-header VALUE       The value for the Accepts header sent in each request.
                                          default: application/json
            --method-name METHODNAME     The name of the method to call.
            --method-arguments JSON      The arguments to pass when calling the method.
            --pretty-print               Will format the output to be more human readable.
            --log-to FILENAME            Log file location.
                                          default: STDERR
            --log-level LEVEL            Logging level. Available Options: debug, info, warn, error, fatal
                                          default: error
            --[no-]options-file [FILENAME]
                                         Path to a file which contains default command line arguments.
                                          default: /Users/jw/.options/vidispine
        -h, --help                       Display this message.

### Available API Methods

#### [collection_create](http://apidoc.vidispine.com/4.2/ref/collection.html#create-a-collection)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_create --method-arguments '{"collection_name":"SomeName"}'

#### [collection_delete](http://apidoc.vidispine.com/4.2/ref/collection.html#delete--collection-\(collection-id\))

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_delete --method-arguments '{"collection_id":"VX-1"}'

#### [collection_get](http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-a-list-of-all-collections)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_get --method-arguments '{"collection_id":"VX-1"}'

#### [collection_items_get](http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-the-items-of-a-collection)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_items_get --method-arguments '{"collection_id":"VX-1"}'

#### [collection_metadata_get](http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-collection-metadata)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_metadata_get --method-arguments '{"collection_id":"VX-1"}'

#### [collection_object_add](http://apidoc.vidispine.com/4.2/ref/collection.html#add-an-item-library-or-collection-to-a-collection)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_object_add --method-arguments '{"collection_id":"VX-1","object_id":"VX-2","type":'item"}'

#### [collection_object_remove](http://apidoc.vidispine.com/4.2/ref/collection.html#remove-an-item-library-or-collection-from-a-collection)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_object_remove --method-arguments '{"collection_id":"VX-1","object_id":"VX-2","type":"item"}'

#### [collection_rename](http://apidoc.vidispine.com/4.2/ref/collection.html#rename-a-collection)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_rename --method-arguments '{"collection_id":"VX-1","name":"NewName"}'

#### [collections_get](http://apidoc.vidispine.com/latest/ref/collection.html#retrieve-a-list-of-all-collections)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collections_get

#### [import_placeholder](http://apidoc.vidispine.com/latest/ref/item/import.html#create-a-placeholder-item)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name import_placeholder --method-arguments '{"video":1}'

#### [import_placeholder_item](http://apidoc.vidispine.com/latest/ref/item/import.html#import-to-a-placeholder-item)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name import_placeholder_item --method-arguments '{"item_id":"VX-1","item_type":"video","uri":"file://srv/media1/test.mov"}'

#### [import_using_uri](http://apidoc.vidispine.com/4.2/ref/item/import.html#import-using-a-uri)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name import_using_uri --method-arguments '{"uri":"file://srv/media1/test.mov"}'

#### [item_collections_get](http://apidoc.vidispine.com/4.2/ref/item/item.html#list-collections-that-contain-an-item)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_collections_get --method-arguments '{"item_id":"VX-1"}'

#### [item_delete](http://apidoc.vidispine.com/latest/ref/item/item.html#delete-a-single-item)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_delete --method-arguments '{"item_id":"VX-117"}'
    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_delete --method-arguments '{"item_id":"VX-117","keepShapeTagMedia":"lowres,webm,original","keepShapeTagStorage":"VX-2,VX-3"}'

#### [item_get](http://apidoc.vidispine.com/latest/ref/item/item.html#get-information-about-a-single-item)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_get --method-arguments '{"item_id":"VX-1"}'

#### [item_metadata_get](http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#get--item-\(id\)-metadata)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_metadata_get --method-arguments '{"item_id":"VX-1"}'

#### [item_metadata_set](http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#add-a-metadata-change-set)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_metadata_set --method-arguments '{"item_id":"VX-1","metadata_document":{ }}'

#### [item_shape_files_get](http://apidoc.vidispine.com/4.2/ref/item/shape.html#get-files-for-shape)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_shape_files_get --method-arguments '{"item_id":"VX-1","shape_id":"VX-2"}'

#### [item_shape_import](http://apidoc.vidispine.com/4.2/ref/item/shape.html#import-a-shape-using-a-uri-or-an-existing-file)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_shape_import --method-arguments '{"item_id":"VX-1","uri":"file:///srv/media1/test.mov","tag":"original"}'

#### [item_thumbnail](http://apidoc.vidispine.com/latest/ref/item/thumbnail.html#start-a-thumbnail-job)

  TODO: ADD EXAMPLE

#### [item_transcode](http://apidoc.vidispine.com/4.2/ref/item/transcode.html#start-an-item-transcode-job)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_transcode --method-arguments '{"item_id":"VX-116", "tag":"original"}'

#### [item_uris_get](http://apidoc.vidispine.com/4.2/ref/item-content.html#get--item-\(item-id\)-uri)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_uris_get --method-arguments '{"item_id":"VX-1"}'
    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_uris_get --method-arguments '{"item_id":"VX-1","tag":"lowres"}'

#### [items_get](http://apidoc.vidispine.com/latest/ref/item/item.html#retrieve-a-list-of-all-items)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name items_get

#### [items_search](http://apidoc.vidispine.com/latest/ref/item/item.html#search-items)

  TODO: ADD EXAMPLE

#### [storage_delete](http://apidoc.vidispine.com/4.2/ref/storage/storage.html#delete--storage-\(storage-id\))

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name storage_delete --method-arguments '{"storage_id":"VX-1"}'

#### [storage_file_get](http://apidoc.vidispine.com/4.2/ref/storage/file.html)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name storage_file_get --method-arguments '{"storage_id":"VX-1"}'

#### [storage_get](http://apidoc.vidispine.com/4.2/ref/storage/storage.html#get--storage-\(storage-id\))

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name storage_get --method-arguments '{"storage_id":"VX-1"}'

#### [storage_method_get](http://apidoc.vidispine.com/4.2/ref/storage/storage.html#storage-methods)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name storage_method_get --method-arguments '{"storage_id":"VX-1"}'

#### [storages_get](http://apidoc.vidispine.com/4.2/ref/storage/storage.html#retrieve-list-of-storages)

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name storages_get

### Utility Methods

#### collection_get_by_name

    Get First Match
    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_get_by_name --method-arguments '{"collection_name":"SomeName"}'
    
    Get All Matches
    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name collection_get_by_name --method-arguments '[{"collection_name":"SomeName"},{"return_first_match":false}]'

#### item_create_with_proxy_using_file_id

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_create_with_proxy_using_file_id --method-arguments '{"storage_id":"VX-1","original_file_path":"test_original.mp4","lowres_file_path":"test_lowres.mp4"}'

#### item_annotation_create

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_annotation_create --method-arguments '{"item_id":"VX-1","inpoint":"00:00:00:00","outpoint":"00:00:00:01","title":"SomeTitle"}'

#### item_annotation_get

    vidispine --host-address 127.0.0.1 --host-port 8080 --method-name item_annotation_get --method-arguments '{"item_id":"VX-1"}'

## Contributing

1. Fork it ( https://github.com/XPlatform-Consulting/vidispine.git )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
