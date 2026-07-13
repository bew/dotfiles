// NOTE: async required so await-ing WebExtension API works 👀
async function do_action() {
  const tab = await tri.webext.activeTab();
  if (!tab.pinned) {
    browser.tabs.remove(tab.id)
  } else {
    tri.excmds.fillcmdline_tmp(2000, "/!\\ tab is pinned, cannot close! /!\\")
  }
}
do_action()
