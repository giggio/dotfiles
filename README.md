# Giovani Bassi's Dotfiles

These are the dotfiles. I'm using
[Dotbot](https://github.com/anishathalye/dotbot)
to automate it.

Installation
------

* Make sure the SSH keys are correct, as some submodules ussh SSH.
* Clone this repo to ~/.dotfiles:
````bash
git clone --recurse-submodules git@github.com:giggio/dotfiles.git $HOME/.dotfiles
````

If you are not the repo owner (Giggio), then you need to use https:

````bash
git clone --recurse-submodules https://github.com/giggio/dotfiles $HOME/.dotfiles
````

* Run the install script `~/.dotfiles/install`.

Forking
-------

You will need to take into consideration that this project uses submodules by
the same author, so you will need to fork those repositories first.
To learn which repositories are being used open at the [.gitmodules]() files and
look for relative submodules (that start with `..`).

Author
------

[Giovanni Bassi](https://twitter.com/giovannibassi)

License
-------

Licensed under the Apache License, Version 2.0.
