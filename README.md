packtpub
========

This repository contains scripts to automate claiming and downloading of free
books on [Packt Publishing](https://www.packtpub.com).


Preparation
-----------
You need an account and store its credentials in `config.rb`. Have a look at
[`config.example.rb`](config.example.rb).

It is recommended to use [rbenv](https://github.com/rbenv/rbenv).


Claim and download
------------------
To claim and download todays free learning eBook run [`fetch.rb`](fetch.rb).


Download destination
--------------------
By specifying a valid directory as `TARGET` in the configuration file, the
directory containing the downloads gets moved into the target directory.
