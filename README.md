# bsch assessment project

The variables used are to help in defining names for specific resource groups, resources, number of virtual machines, address spaces, allocation of ip/addresses and creation of the user.


The creation of the infrastructure is done by creating an VNet and allocating an address space, for which we create an subnet for better usage of the addresses and creating public and private ip addresses which are associated with a NIC and afterwards with a virtual machine.

The virtual machine I opted for a image of Ubuntu 16.04 with a standard virtual machine size. The creation of username is done through a variable that holds the name and the password is generated randomly at creation being different for each machine.

I've set public ip addresses for the virtual machines, since the solution I opted for using the ssh resource doesn't support to well the usage of this resource with an bastion. In this case I've used the public ip to connect to the virtual machine and afterwards reach to the next machine via the private ip address.

The roundrobin execution is done by sending a script to a machine and capturing the output via ssh resource and stored in a terraform variable called ping_result which holds the encoded json result from the machines.


More details can be obtained by viewing the variables.tf file, which also holds description for mostly of the variables.
