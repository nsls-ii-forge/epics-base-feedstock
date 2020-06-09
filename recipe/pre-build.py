import os
from pathlib import Path

# set INSTALL_LOCATION in CONFIG_SITE.local
PREFIX = os.environ["PREFIX"]
EPICS_BASE = Path(PREFIX, "epics")
RELATIVE_INSTALL_LOCATION = Path(os.path.relpath(EPICS_BASE))
Path("configure/CONFIG_SITE.local").write_text(
    f"INSTALL_LOCATION = $(TOP)/{RELATIVE_INSTALL_LOCATION.as_posix()}\n"
)

# create activate/deactivate scripts
EPICS_HOST_ARCH = os.environ["EPICS_HOST_ARCH"]
EPICS_BASE_VERSION = os.environ["PKG_VERSION"]
EPICS_BASE = r"%CONDA_PREFIX%\epics"
EPICS_BASE_HOST_BIN = rf"{EPICS_BASE}\bin\{EPICS_HOST_ARCH}"
variables = (
    "EPICS_BASE",
    "EPICS_HOST_ARCH",
    "EPICS_BASE_HOST_BIN",
    "EPICS_BASE_VERSION",
)
activate_d = Path(PREFIX, "etc", "conda", "activate.d")
activate_d.mkdir(parents=True, exist_ok=True)
with open(activate_d / "epics-base_activate.bat", "w") as f:
    f.write("@echo off\n")
    for var in variables:
        f.write(f'set "{var}={globals()[var]}"\n')
    f.write(f'set "PATH={EPICS_BASE_HOST_BIN};%PATH%"\n')

deactivate_d = Path(PREFIX, "etc", "conda", "deactivate.d")
deactivate_d.mkdir(parents=True, exist_ok=True)
with open(deactivate_d / "epics-base_deactivate.bat", "w") as f:
    f.write("@echo off\n")
    # Remove EPICS_BASE_HOST_BIN from PATH
    f.write("setlocal EnableDelayedExpansion\n")
    f.write('set "NEW_PATH=!PATH:%EPICS_BASE_HOST_BIN%;=!"\n')
    f.write('endlocal & set "PATH=%NEW_PATH%"\n')
    # Unset variables
    for var in variables:
        f.write(f'set "{var}="\n')
