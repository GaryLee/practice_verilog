# practice_verilog

My Verilog practice.

# Installation

Before using this command, you should have invoke, textual Python packages installed already. 
If they are not installed, use following PIP command to install them.

```sh
>>> pip install invoke textual
```

# Create new subproject.

Use invoke tasks to create an new verilog project with Cocotb simulation environment.

```sh
>>> invoke create-project
```

The following UI will be displayed. Fill the fields and press the `CREATE` button to create the project under current folder.

![p](images/gui.png)