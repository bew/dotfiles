/** @jsxImportSource @opentui/solid */
// Global V2 TUI plugin: show the selected account of the current provider and
// switch it.
//
// The accounts of the provider selected in the prompt box are shown in the
// session composer and on the home screen, with the active one highlighted.
// Clicking an account activates it.
//
// The `@jsxImportSource` pragma pins the JSX runtime to `@opentui/solid`, so
// the file compiles the same whether or not the loader configures it.

import { Plugin, usePlugin } from "@opencode/plugin/tui";
import type { Context } from "@opencode/plugin/tui/context";
import { For, Show, createSignal } from "solid-js";

// One credential of one integration, reduced to the fields the status surfaces
// need.
// The credential secret (`CredentialEntry.value`) is deliberately not read.
type Account = {
  credentialID: string;
  integrationID: string;
  label: string;
  active: boolean;
};

// Every event that can change the set or the active state of credentials.
const ACCOUNT_EVENTS = [
  "credential.updated",
  "credential.switched",
  "integration.updated",
] as const;

// A mouse "click" is the host's `onMouseUp` pattern: left button only, and the
// event is stopped so it does not also reach the surface behind the chip.
function handleClick(event: { button: number; stopPropagation: () => void }, onClick: () => void): void {
  if (event.button !== 0) {
    return;
  }
  event.stopPropagation();
  onClick();
}

// Status line showing the current provider's accounts, the active one
// highlighted.
// Clicking an account activates it.
// Renders only when that provider has 2+ accounts.
function AccountBar(props: {
  accounts: readonly Account[];
  onSelect: (credentialID: string) => void;
}) {
  const context = usePlugin();
  // The provider currently selected in the prompt box owns the accounts shown.
  const rows = () =>
    props.accounts.filter(
      (account) => account.integrationID === context.ui.model.current()?.providerID,
    );
  // Inactive accounts sit on a dark-gray chip; the active one pops on accent.
  const idleBar = () => context.theme.hue.gray[800];
  const activeBar = () => context.theme.hue.accent[400];
  return (
    <Show when={rows().length >= 2}>
      <box flexDirection="row">
        <text fg={context.theme.text.default}>Selected account:</text>
        <For each={rows()}>
          {(account) => (
            <text
              bg={account.active ? activeBar() : idleBar()}
              fg={account.active ? context.theme.background.default : context.theme.text.default}
              onMouseUp={(event) => handleClick(event, () => props.onSelect(account.credentialID))}
            >
              {` ${account.label} `}
            </text>
          )}
        </For>
      </box>
    </Show>
  );
}

export default Plugin.define({
  id: "account-switcher.tui",
  setup(context: Context) {
    const [accounts, setAccounts] = createSignal<readonly Account[]>([]);

    // Surface a failed credential round-trip without crashing the plugin.
    function reportError(error: unknown): void {
      context.ui.toast.show({
        message: `account-switcher: ${error instanceof Error ? error.message : String(error)}`,
        variant: "error",
      });
    }

    // Load every credential with the fields the chip needs.
    // The server orders by `active` first, so re-sort by id (which is
    // time-ordered) to keep the account order stable as the active one changes.
    async function refresh(): Promise<void> {
      const credentials = await context.client.credential.list();
      setAccounts(
        [...credentials]
          .sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
          .map((credential) => ({
          credentialID: credential.id,
          integrationID: credential.integrationID,
          label: credential.label,
          active: credential.active,
        })),
      );
    }

    // Activate one account, ignoring a click on the account already active.
    async function activate(credentialID: string): Promise<void> {
      const account = accounts().find((entry) => entry.credentialID === credentialID);
      if (!account || account.active) {
        return;
      }
      try {
        await context.client.credential.activate({ credentialID });
      } catch (error) {
        reportError(error);
        return;
      }
      await refresh();
      context.ui.toast.show({ message: "Account switched" });
    }

    // Slot claims and event subscriptions must all be released on unload.
    const disposers: Array<() => void> = [
      context.ui.slot({
        append: "home.footer.status",
        render: () => <AccountBar accounts={accounts()} onSelect={activate} />,
      }),
      context.ui.slot({
        append: "session.composer.top",
        render: () => <AccountBar accounts={accounts()} onSelect={activate} />,
      }),
    ];

    void refresh().catch(reportError);
    for (const type of ACCOUNT_EVENTS) {
      disposers.push(
        context.data.on(type, () => {
          void refresh().catch(reportError);
        }),
      );
    }

    return () => {
      for (const dispose of disposers) {
        dispose();
      }
    };
  },
});
