# SktlToLiquid

Converter for [Northpass](https://www.northpass.com/) custom templates. Converts **.sktl** files to **.liquid** files.

## Before you start

This is **not** a fully featured .sktl -> .liquid converter. It was written to smoothly transfer our clients to **liquid** templates and covers only needed part for that. Successfully converted 99.6 % of our clients templates.

## Installation

Run in terminal

```bash
gem install sktl_to_liquid
```

## Usage

```
Usage: sktl_to_liquid --sktl directory/with/.sktl --liquid directory/to/output/.liquid
    -s, --sktl SKTL                  Location of directory with SKTL files
    -l, --liquid LIQUID              Location of directory to output Liquid files
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SchoolKeep/sktl_to_liquid.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
