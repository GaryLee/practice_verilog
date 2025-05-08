#!python
# coding: utf-8

import re
import shutil
import sys
import os
from pathlib import Path
from invoke import task, Program, Collection
from textual import on
from textual.app import App, ComposeResult
from textual.widgets import Footer, Header, Input, Label, Button, Rule, Select, Checkbox, RichLog
from textual.containers import HorizontalGroup, Grid, Center
from textual.validation import Regex, Length, Validator, ValidationResult
from rich.text import Text
from types import SimpleNamespace

COCOTB_TEMPLATE = "./cocotb_template"

CSS = """
    Screen {
        align: center middle;
    }

    Label {
        padding: 1 1;
    }

    Input.-valid {
        border: tall $success 60%;
    }
    Input.-valid:focus {
        border: tall $success;
    }

    .item_grid {
        grid-size: 2;
        grid-columns: 1fr 4fr;
        width: 70%;
        height: auto;
        margin: 1 1;
    }
"""

SUPPORTED_SIMULATORS = [
    "icarus",
    "activehdl",
    "coverage",
    "cvc",
    "ghdl",
    "ius",
    "modelsim",
    "nvc",
    "questa",
    "riviera",
    "vcs",
    "verilator",
    "xcelium",
]

SUPPORTED_TOP_LANG = {
    "Verilog/SystemVerilog": "verilog",
    "VHDL": "vhdl",
}

class FolderDontExistCheck(Validator):
    """A validator for checking if the folder doesn't exist."""

    def validate(self, value: str) -> ValidationResult:
        """Check if the folder doesn't exist."""
        folder = Path(value)
        if folder.exists():
            if folder.is_dir():
                return self.failure("Folder already exists.")
            else:
                return self.failure("File with the same name already exists.")
        return self.success()

class FolderExistCheck(Validator):
    """A validator for checking if the folder exist."""

    def validate(self, value: str) -> ValidationResult:
        """Check if the folder doesn't exist."""
        folder = Path(value)
        if folder.is_dir():
            return self.success()
        elif not folder.exists():
            return self.failure("Folder doesn't exist.")
        elif folder.is_file():
            return self.failure("It's a file, not a folder.")
        else:
            return self.failure("Unknown error.")


class CreaterProjectUi(App):
    CSS = CSS
    BINDINGS = [("d", "toggle_dark", "Toggle dark mode"), ("q", "quit", "Quit")]

    def compose(self) -> ComposeResult:
        yield Header("Create Project")
        yield Footer()
        with Center():
            with Grid(classes="item_grid"):
                yield Label("Project Name:")
                yield Input(
                    placeholder="Project Name",
                    id="project_name",
                    tooltip="Enter the project name",
                    validators=[
                        Regex(
                            r"^[a-zA-Z0-9_]+$",
                            failure_description="Only alphanumeric characters and underscores are allowed.",
                        ),
                        Length(
                            minimum=1,
                            maximum=64,
                            failure_description="Project name must be between 1 and 64 characters.",
                        ),
                        FolderDontExistCheck(),
                    ],
                )
                yield Label("Parent Folder:")
                yield Input(
                    placeholder="Parent Folder",
                    id="parent_folder",
                    tooltip="Enter the parent folder",
                    value=os.getcwd(),
                    validators=[
                        Regex(
                            r"^[a-zA-Z0-9_ /]+$",
                            failure_description="Only alphanumeric characters and underscores are allowed.",
                        ),
                        Length(
                            minimum=1,
                            maximum=1024,
                            failure_description="Project folder must be between 1 and 1024 characters.",
                        ),
                        FolderExistCheck(),
                    ],
                )
                yield Label("DUT File:")
                yield Input(
                    placeholder="DUT file.",
                    value="dut.sv",
                    id="dut_file",
                    tooltip="Enter the filename of DUT.",
                    validators=[
                        Regex(
                            r"^[a-zA-Z0-9_]+\.(v|sv|vhdl)$",
                            failure_description="Only alphanumeric characters and underscores are allowed.",
                        ),
                        Length(
                            minimum=1,
                            maximum=64,
                            failure_description="DUT name must be between 1 and 64 characters including file extension.",
                        ),
                    ],
                )
                yield Label("Test Proc:")
                yield Input(
                    placeholder="Test procedure name.",
                    value="test_proc",
                    id="test_proc",
                    tooltip="Enter test procedure name.",
                    validators=[
                        Regex(
                            r"^[a-zA-Z0-9_]+$",
                            failure_description="Only alphanumeric characters and underscores are allowed.",
                        ),
                        Length(
                            minimum=1,
                            maximum=64,
                            failure_description="Test procedure name must be between 1 and 64 characters.",
                        ),
                    ],
                )
                yield Label("DUT module:")
                yield Input(
                    placeholder="DUT top module.",
                    value="dut",
                    id="dut_module",
                    tooltip="Enter the top module name of DUT.",
                    validators=[
                        Regex(
                            r"^[a-zA-Z0-9_]+$",
                            failure_description="Only alphanumeric characters and underscores are allowed.",
                        ),
                        Length(
                            minimum=1,
                            maximum=64,
                            failure_description="DUT name must be between 1 and 64 characters.",
                        ),
                    ],  
                )
                yield Label("HW Language:")
                yield Select(
                    options=zip(SUPPORTED_TOP_LANG.keys(), SUPPORTED_TOP_LANG.keys()),
                    allow_blank=False,
                    id="toplevel_lang",
                )
                yield Label("Compile args:")
                yield Input(
                    placeholder="Compile arguments. Eg, -D xxx=yyy.",
                    id="compile_args",
                    tooltip="Enter the compile arguments",
                )
                yield Label("Simulator:")
                yield Select(
                    options=zip(SUPPORTED_SIMULATORS, SUPPORTED_SIMULATORS),
                    allow_blank=False,
                    id="simulator",
                )
                yield Label("Simulation arguments:")
                yield Input(
                    placeholder="Simulator arguments. Eg, --vcd=anyname.vcd.",
                    id="sim_args",
                    tooltip="Enter the simulator arguments",
                )
                yield Label("Waveform:")
                yield Checkbox("Enable", value=True, id="waves", tooltip="Enable or disable waveform generation.")

        with HorizontalGroup():
            yield Rule()
            yield Button("CREATE", id="btn_ok", variant="primary")
            yield Button("QUIT", id="btn_cancel", variant="default")
            yield Rule()
        
        self._rich_log = RichLog(id="rich_log")
        yield self._rich_log

    def action_toggle_dark(self) -> None:
        self.theme = (
            "textual-dark" if self.theme == "textual-light" else "textual-light"
        )

    def rich_log(self, *messages, style=None) -> None:
        if isinstance(messages, str):
            messages = [messages,]
        for message in messages:
            if isinstance(message, str):
                self._rich_log.write(Text(message, style=style))
            else:
                self._rich_log.write(message)

    def action_create_project(self) -> None:
        ns = SimpleNamespace()
        ns.project_name = self.get_widget_by_id(f"project_name").value
        ns.parent_folder = self.get_widget_by_id(f"parent_folder").value
        ns.dut_file = self.get_widget_by_id("dut_file").value
        ns.dut_module = self.get_widget_by_id("dut_module").value
        ns.test_proc = self.get_widget_by_id("test_proc").value
        ns.toplevel_lang = SUPPORTED_TOP_LANG[self.get_widget_by_id("toplevel_lang").value]
        ns.compile_args = self.get_widget_by_id("compile_args").value
        ns.simulator = self.get_widget_by_id("simulator").value
        ns.sim_args = self.get_widget_by_id("sim_args").value
        ns.waves = 1 if self.get_widget_by_id("waves").value else 0
        self.do_create_project(ns)
        
    def do_create_project(self, ns):
        # Pre-check the input values.
        error_count = 0
        error_style = "magenta"
        info_style = ""
        success_style = "green"
        if not Path(ns.parent_folder).exists():
            self.rich_log("Project folder don't exists.", style=error_style)
            error_count += 1
        if not re.match(r"^[a-zA-Z0-9_]+$", ns.project_name):
            self.rich_log("Project name is invalid.", style=error_style)
            error_count += 1
        if not re.match(r"^[a-zA-Z0-9_]+$", ns.dut_module):
            self.rich_log("DUT module name is invalid.", style=error_style)
            error_count += 1
        if error_count:
            return
        # Pre-check the parameters.
        if not Path(COCOTB_TEMPLATE).is_dir():
            self.rich_log(f"Folder {COCOTB_TEMPLATE} doesn't exist.", style=error_style)
            error_count += 1
        target_folder = Path(".") / ns.parent_folder / ns.project_name 
        if Path(target_folder).exists():
            self.rich_log(f"Folder {target_folder} already exists.", style=error_style)
            error_count += 1
        if error_count:
            return
                
        # Create the project.
        self.rich_log("Creating project...", style=info_style)

        os.makedirs(target_folder)
        if not Path(target_folder).is_dir():
            self.rich_log(f"Failed to create folder {target_folder}.", style=error_style)
            return
        self.rich_log(f"Created folder {target_folder}.", style=info_style)

        for fn in os.listdir(COCOTB_TEMPLATE):
            if fn.lower() in ['makefile', 'dut.sv', 'test_proc.py']:
                with open(Path(target_folder) / fn, "w") as f:
                    content = open(Path(COCOTB_TEMPLATE) / fn).read()
                    f.write(content.format(**ns.__dict__))
                self.rich_log(f"Generated {fn} to {target_folder}", style=info_style)
            else:
                shutil.copy(Path(COCOTB_TEMPLATE) / fn, target_folder)
                self.rich_log(f"Copied {fn} to {target_folder}", style=info_style)
        self.rich_log("Project created succssfully.", style=success_style)

    @on(Input.Changed)
    def show_invalid_reasons(self, event: Input.Changed) -> None:
        if event.validation_result and not event.validation_result.is_valid:
            self.rich_log(event.validation_result.failure_descriptions, style="magenta")
        else:
            self._rich_log.clear()

    @on(Button.Pressed, "#btn_cancel")
    def on_btn_cancel_pressed(self) -> None:
        self.exit()

    @on(Button.Pressed, "#btn_ok")
    def on_btn_ok_pressed(self) -> None:
        self.action_create_project()


@task
def create_project(c):
    app = CreaterProjectUi()
    app.run()


if __name__ == "__main__":
    # Following code allows to run the tasks without using invoke command tool.
    # However, the "invoke command" still works.
    local_task_collection = Collection.from_module(sys.modules[__name__])
    Program(namespace=local_task_collection, version="1.0").run()
