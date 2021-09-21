# Hiera templater without puppet

Requires facter and hiera gems, compatible with latest gems and versions installed on MSM instances.

## Background

The idea behind this prohect is to allow the power of hiera to be extended to folks that wish to use it
in scenarios where they don't want to use puppet.

## Operation - basics

The CLI has only one required option, a file or a path to be parsed, path parsing must be enabled by passing the -r (recursive flag) and
the CLI will then look for any file suffixed in .erb.

In basic mode of operation the templater has a safeguard blocking the overwrite of existing files (possibly from previous runs) unless the
-f flag (force) is also provided.

Syntax as per help

```
andrew.smith@C02Z2A0SLVCG hiera-templater % ruby hiera_templater.rb 
Usage: hiera_templater.rb [options] <file/folder>

Processes a specific .erb template or a folder hierarchy for .erb files.
Note that only files named with an .erb suffix will be processed and the output file will match the
name but with the suffix removed.

The erb files in the folder must use hiera('key') to retrieve a data item.
    -c, --config=CONFIG_FILE         hiera configuration file (default /etc/puppet/hiera.yaml)
    -r, --recurse                    Recurse a specified folder rather than specify a file name
    -f, --force                      Force overwrite if output file exists
    -h, --help                       Prints this help
andrew.smith@C02Z2A0SLVCG hiera-templater % 
```

NOTE: In all modes of operation please attempt to utilise the recurse feature to process all your files, do NOT wrap this in another script as you will pay a 0.6 second penalty for each time the Facter library is initialised!!

In basic operation the files are delivered to the same folder as the erb template with the erb suffix removed. All template files must have the trailing .erb suffix.

ERB templates are processed with one of 3 hiera DSL lookup functions, these are..

### hiera(<hey>, \[default\])

A key, regardless of type is retrieved, this form will return any type including hash and array and can be given an optional default value for
values that cannot be found.

The hiera function ALSO includes a lookup for facter keys if not found in hiera, neither of the two other lookup functions do this.

### hiera_array(<key>, \[default\])

Type checked version of the above that will fail if a non array type is found.

### hiera_hash(<key>, \[default\])

Type checked version of the above that will fail if a non hash type is found.

## Operation - More DSL usage

If one wishes to output files to a specific folder rather than have then land automatically as placed by the script one can use one of 2 high level DSL
functions.

Noting that as soon as either of these or the more advanced custom_out function is used one is entirely responsible for the output to file, the tool will
no longer automatically do that for you in these cases.

### mkdir_p(\<path\>, \[owner: \<owner\>\], \[group: \<group\>\], \[mode: \<mode\>\]))

This DSL function calls custom_out and is a helper to create a folder structure recursively with optional ownership and mode specifications.

### custom_file(\<path\>, \[owner: \<owner\>\], \[group: \<group\>\], \[mode: \<mode\>\])

This DSL function calls custom_out with a preset block to ensure the output file is written with the path and optionally ownership and mode specified.

Note that custom_out blocks are performed in the order specified but following rendering so please ensure that any dependent file strictures are made (mkdir_p) before custome_file is used if it is dependent upon that path.

## Operation - Advanced usage

The templater implements custom_out as a function which takes a block of Ruby code as a parameter, this block should implement a parameter which will receive the rendered content (whether it uses it or not) and is free to utilise that content for more advanced purposes.

## DSL Example
```
[root@ip-10-96-3-54 ~]# cat testing/dsl.erb 
[Facter only]
My IP is: <%= hiera('ipaddress_primary') %>

[Something missing]
  Non existant: <%= hiera('clearly::not_existing', 'but has default') %>

<% mkdir_p('/tmp/test')
   mkdir_p('/tmp/test2', owner: 'sysadmin', mode: 0500)
   mkdir_p('/tmp/test3', group: 'sysadmin', mode: 0550)
   mkdir_p('/tmp/test4', owner: 'root', group: 'sysadmin', mode: 0750)
   custom_file('/tmp/test4/testfile', owner: 'root', group: 'sysadmin', mode: 0640) -%>
```

## Advanced example
```
[root@ip-10-96-3-54 ~]# cat testing/custom_out.erb 
[Facter only]
My IP is: <%= hiera('ipaddress_primary') %>

[Something missing]
  Non existant: <%= hiera('clearly::not_existing', 'but has default') %>

<% custom_out do |content|
    File.write('/tmp/footest', content) 
    FileUtils.chmod(0640, '/tmp/footest')
    FileUtils.chown('root', 'sysadmin', '/tmp/footest')
  end -%>
<% custom_out { |content| puts content } -%>
[root@ip-10-96-3-54 ~]# 
```