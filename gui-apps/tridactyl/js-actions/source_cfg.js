// % Usage:
// source_cfg ./file
// source_cfg for-os:THE-OS ./file
//
// Example values for THE-OS: linux, win, mac
// ref: https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/runtime/PlatformOs

async function do_action(args) {
  let condition, relative_path;

  if (args.length == 1) {
    relative_path = args[0];
  } else if (args.length == 2) {
    condition = args[0];
    relative_path = args[1];
  }

  if (condition && condition.startsWith("for-os:")) {
    const for_os = condition.split(":")[1]; // Extract OS name after "for-os:"
    const info = await browser.runtime.getPlatformInfo();

    if (info.os !== for_os) {
      console.log(`Sourcing '${relative_path}' skipped, OS (${info.os}) != ${for_os}`);
      return; // OS does not match
    }
  }

  console.log(`Sourcing '${relative_path}'…`)
  tri.excmds.source("~/.config/tridactyl/" + relative_path);
}

// Discard first item (empty string..)
// See discussion starting at:
//   https://matrix.to/#/!AXdLfOGmSqOJipwjRW:matrix.org/$cRPKgKqRZDsh_wV2AxMbViqAQcb-MiV3qSuYP0KfpRA?via=matrix.org
JS_ARGS.shift()

do_action(JS_ARGS);
// NOTE: The command that invokes this action should be:
//   jsb -d§ -r js-actions/source_cfg.js§
// /!\ The ending `§` is NOT separated from the filename
//   … until that PR is merged and released: https://github.com/tridactyl/tridactyl/pull/5222
