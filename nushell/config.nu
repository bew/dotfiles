# Nushell Config File
# NOTE: ONLY loaded when starting an interactive shell

# NOTE: $NU_LIB_DIRS must include $nu.default-config-dir for these import to work
#   (must be set _before_ this file is parsed, in `env.nu`)

use bewcfg_prompt.nu

# Import aliases/utils in shell scope
use bewcfg_aliases_and_short_funcs.nu *
use bewcfg_shell_utils_for_job_control.nu *
use bewcfg_shell_utils_misc.nu *

use bewcfg_config.nu
$env.config = (bewcfg_config get_config)
