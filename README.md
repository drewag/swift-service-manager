# swift-service-manager
Manage [Swift Serve](https://github.com/drewag/swift-serve) services locally and remotely more easily

Installation
-----------

Clone the repository locally and change into its directory

    git clone https://github.com/drewag/swift-service-manager
    cd swift-service-manager

Build the binary

    make prod
    
Install the binary as a user command

    make install

Usage
-----

Run the command to get a list of available commands

    ssm
    
Run any command with the option `-h` or `--help` to get help on that specific command:

    ssm edit -h
