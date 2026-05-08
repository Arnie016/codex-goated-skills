import Testing
@testable import SkillBar

struct MenuBarViewTests {
    @Test
    func synchronizedSelectedIconIDKeepsCurrentSelectionWhenStillVisible() {
        let selection = MenuBarView.synchronizedSelectedIconID(
            currentSelection: "power-sentry",
            availableIDs: ["skillbar", "power-sentry", "workspace-doctor"]
        )

        #expect(selection == "power-sentry")
    }

    @Test
    func synchronizedSelectedIconIDFallsBackWhenScopeDropsCurrentSelection() {
        let selection = MenuBarView.synchronizedSelectedIconID(
            currentSelection: "power-sentry",
            availableIDs: ["skillbar", "workspace-doctor"]
        )

        #expect(selection == "skillbar")
    }

    @Test
    func synchronizedSelectedIconIDClearsWhenNoIconsRemain() {
        let selection = MenuBarView.synchronizedSelectedIconID(
            currentSelection: "power-sentry",
            availableIDs: []
        )

        #expect(selection == nil)
    }

    @Test
    func pinnedMenuBarRecoveryButtonTitleUsesCompactCopyForTightStrip() {
        let title = MenuBarView.pinnedMenuBarRecoveryButtonTitle(
            compact: true,
            defaultTitle: "Use Detected Repo + Create Folder"
        )

        #expect(title == "Use Repo")
    }

    @Test
    func pinnedMenuBarRecoveryButtonTitleKeepsFullCopyForPrimaryStrip() {
        let title = MenuBarView.pinnedMenuBarRecoveryButtonTitle(
            compact: false,
            defaultTitle: "Use Detected Repo + Create Folder"
        )

        #expect(title == "Use Detected Repo + Create Folder")
    }

    @Test
    func menuBarRecoveryRepoMenuTitleUsesShortCopyForCompactStrip() {
        let title = MenuBarView.menuBarRecoveryRepoMenuTitle(compact: true)

        #expect(title == "Repo")
    }

    @Test
    func menuBarRecoveryRepoMenuTitleUsesExplicitCopyForPrimaryStrip() {
        let title = MenuBarView.menuBarRecoveryRepoMenuTitle(compact: false)

        #expect(title == "Repo Options")
    }

    @Test
    func packRecoveryRepoMenuTitleKeepsRecoveryActionsGrouped() {
        let title = MenuBarView.packRecoveryRepoMenuTitle()

        #expect(title == "Repo Options")
    }

    @Test
    func packBrowseActionIsSecondaryWhenIncompletePackCanInstall() {
        #expect(!MenuBarView.shouldPromotePackBrowseAction(
            canRunInstallAction: true,
            isComplete: false,
            isFocused: false
        ))
    }

    @Test
    func packBrowseActionIsPrimaryWhenPackIsComplete() {
        #expect(MenuBarView.shouldPromotePackBrowseAction(
            canRunInstallAction: true,
            isComplete: true,
            isFocused: false
        ))
    }

    @Test
    func packBrowseActionIsSecondaryWhenPackCatalogIsAlreadyFocused() {
        #expect(!MenuBarView.shouldPromotePackBrowseAction(
            canRunInstallAction: false,
            isComplete: false,
            isFocused: true
        ))
    }

    @Test
    func iconGridTitleNamesUnfilteredCatalog() {
        #expect(MenuBarView.iconGridTitle(
            hasSearchText: false,
            hasPackFocus: false
        ) == "All Icons")
    }

    @Test
    func iconGridTitleNamesSearchResults() {
        #expect(MenuBarView.iconGridTitle(
            hasSearchText: true,
            hasPackFocus: false
        ) == "Search Results")
    }

    @Test
    func iconGridTitleNamesPackScope() {
        #expect(MenuBarView.iconGridTitle(
            hasSearchText: false,
            hasPackFocus: true
        ) == "Pack Icons")
    }

    @Test
    func iconGridTitleNamesCombinedScope() {
        #expect(MenuBarView.iconGridTitle(
            hasSearchText: true,
            hasPackFocus: true
        ) == "Scoped Icons")
    }

    @Test
    func settingRowSecondaryMenuTitleNamesRepoOptions() {
        let title = MenuBarView.settingRowSecondaryMenuTitle(for: "Repo Root")

        #expect(title == "Repo Options")
    }

    @Test
    func settingRowSecondaryMenuTitleNamesFolderOptions() {
        let title = MenuBarView.settingRowSecondaryMenuTitle(for: "Installed Skills")

        #expect(title == "Folder Options")
    }

    @Test
    func settingRowSecondaryMenuTitleNamesActiveViewOptions() {
        let title = MenuBarView.settingRowSecondaryMenuTitle(for: "Active View")

        #expect(title == "View Options")
    }

    @Test
    func activeScopeChipTitleTrimsVisibleFilterCopy() {
        let title = MenuBarView.activeScopeChipTitle(prefix: "Search", value: "  icon cleanup  ")

        #expect(title == "Search: icon cleanup")
    }

    @Test
    func activeScopeChipTitleHidesEmptyValues() {
        #expect(MenuBarView.activeScopeChipTitle(prefix: "Search", value: "  \n  ") == nil)
        #expect(MenuBarView.activeScopeChipTitle(prefix: "Pack", value: nil) == nil)
    }

    @Test
    func activeScopeChipTitleCapsLongValues() {
        let title = MenuBarView.activeScopeChipTitle(
            prefix: "Pack",
            value: "Very Long Pack Name For A Narrow Menu",
            maxValueLength: 12
        )

        #expect(title == "Pack: Very Long...")
    }

    @Test
    func quickSetupDirectCreateShowsWhenFolderMissing() {
        #expect(MenuBarView.shouldShowQuickSetupDirectCreateFolder(
            folderExists: false
        ))
    }

    @Test
    func quickSetupDirectCreateHidesWhenFolderExists() {
        #expect(!MenuBarView.shouldShowQuickSetupDirectCreateFolder(
            folderExists: true
        ))
    }

    @Test
    func pinnedTileButtonShowsWhenPinnedEntryIsLive() {
        #expect(MenuBarView.shouldShowPinnedTileButton(
            hasPinnedSelection: true,
            canRevealPinnedEntry: true
        ))
    }

    @Test
    func pinnedTileButtonHidesWhenPinnedEntryIsStale() {
        #expect(!MenuBarView.shouldShowPinnedTileButton(
            hasPinnedSelection: true,
            canRevealPinnedEntry: false
        ))
    }

    @Test
    func pinnedTileButtonHidesBeforeAnIconIsPinned() {
        #expect(!MenuBarView.shouldShowPinnedTileButton(
            hasPinnedSelection: false,
            canRevealPinnedEntry: false
        ))
    }

    @Test
    func pinnedMenuBarUpdateShowsForLiveInstalledPinnedSkill() {
        #expect(MenuBarView.shouldShowPinnedMenuBarUpdate(
            hasPinnedSelection: true,
            canRevealPinnedEntry: true,
            isInstalled: true
        ))
    }

    @Test
    func pinnedMenuBarUpdateHidesForRecoveryStates() {
        #expect(!MenuBarView.shouldShowPinnedMenuBarUpdate(
            hasPinnedSelection: true,
            canRevealPinnedEntry: false,
            isInstalled: true
        ))
        #expect(!MenuBarView.shouldShowPinnedMenuBarUpdate(
            hasPinnedSelection: true,
            canRevealPinnedEntry: true,
            isInstalled: false
        ))
        #expect(!MenuBarView.shouldShowPinnedMenuBarUpdate(
            hasPinnedSelection: false,
            canRevealPinnedEntry: false,
            isInstalled: false
        ))
    }

    @Test
    func iconTileHelpTextPointsToVisibleManageFlow() {
        let helpText = MenuBarView.iconTileHelpText(
            displayName: "SkillBar",
            statusLabel: "Installed",
            categoryLabel: "Platform",
            primaryDescription: "Manage skills from the menu bar."
        )

        #expect(helpText.contains("Select to inspect, reveal, install, update, or pin."))
        #expect(!helpText.localizedCaseInsensitiveContains("double-click"))
    }

    @Test
    func selectedIconLocalActionsIgnoreRepoReadinessWhenIdle() {
        #expect(!MenuBarView.shouldDisableSelectedIconCommand(
            action: .useDefaultIcon,
            isBusy: false,
            hasValidRepo: false
        ))
        #expect(!MenuBarView.shouldDisableSelectedIconCommand(
            action: .pinToMenuBar,
            isBusy: false,
            hasValidRepo: false
        ))
    }

    @Test
    func selectedIconInstallActionsRequireAReadyRepo() {
        #expect(MenuBarView.shouldDisableSelectedIconCommand(
            action: .installPinnedSkill,
            isBusy: false,
            hasValidRepo: false
        ))
        #expect(MenuBarView.shouldDisableSelectedIconCommand(
            action: .installAndPin,
            isBusy: false,
            hasValidRepo: false
        ))
        #expect(!MenuBarView.shouldDisableSelectedIconCommand(
            action: .installAndPin,
            isBusy: false,
            hasValidRepo: true
        ))
    }

    @Test
    func selectedIconActionsStayDisabledWhileBusy() {
        #expect(MenuBarView.shouldDisableSelectedIconCommand(
            action: .useDefaultIcon,
            isBusy: true,
            hasValidRepo: true
        ))
    }

    @Test
    func catalogRowLocalAccessoryActionsIgnoreRepoReadinessWhenIdle() {
        #expect(!MenuBarView.shouldDisableCatalogRowAccessoryAction(
            action: .useDefaultIcon,
            isBusy: false,
            hasValidRepo: false
        ))
        #expect(!MenuBarView.shouldDisableCatalogRowAccessoryAction(
            action: .pinToMenuBar,
            isBusy: false,
            hasValidRepo: false
        ))
        #expect(MenuBarView.shouldDisableCatalogRowAccessoryAction(
            action: .installPinnedSkill,
            isBusy: false,
            hasValidRepo: false
        ))
        #expect(!MenuBarView.shouldDisableCatalogRowAccessoryAction(
            action: .installPinnedSkill,
            isBusy: false,
            hasValidRepo: true
        ))
    }

    @Test
    func catalogRowPinnedInstallAccessoryBecomesThePrimaryRecoveryAction() {
        #expect(MenuBarView.shouldPromoteCatalogRowAccessoryAction(action: .installPinnedSkill))
        #expect(!MenuBarView.shouldPromoteCatalogRowAccessoryAction(action: .installAndPin))
        #expect(!MenuBarView.shouldPromoteCatalogRowAccessoryAction(action: .pinToMenuBar))
        #expect(!MenuBarView.shouldPromoteCatalogRowAccessoryAction(action: .useDefaultIcon))
    }

    @Test
    func catalogRowPinnedUninstalledSkillHidesDuplicateInstallAction() {
        #expect(!MenuBarView.shouldShowCatalogRowCLIAction(
            isInstalled: false,
            accessoryAction: .installPinnedSkill
        ))
        #expect(MenuBarView.shouldShowCatalogRowCLIAction(
            isInstalled: false,
            accessoryAction: .installAndPin
        ))
        #expect(MenuBarView.shouldShowCatalogRowCLIAction(
            isInstalled: true,
            accessoryAction: .useDefaultIcon
        ))
    }

    @Test
    func iconCLICommandsStayGatedByBusyAndRepoState() {
        #expect(MenuBarView.shouldDisableIconCLICommand(isBusy: true, hasValidRepo: true))
        #expect(MenuBarView.shouldDisableIconCLICommand(isBusy: false, hasValidRepo: false))
        #expect(!MenuBarView.shouldDisableIconCLICommand(isBusy: false, hasValidRepo: true))
    }

    @Test
    func selectedIconUpdateShowsForPinnedInstalledSkill() {
        #expect(MenuBarView.shouldShowSelectedIconUpdate(
            isInstalled: true,
            primaryAction: .useDefaultIcon
        ))
        #expect(MenuBarView.shouldShowSelectedIconUpdate(
            isInstalled: true,
            primaryAction: .pinToMenuBar
        ))
        #expect(!MenuBarView.shouldShowSelectedIconUpdate(
            isInstalled: false,
            primaryAction: .installAndPin
        ))
    }

    @Test
    func selectedIconRevealOnlyRequiresAConcreteSkillPath() {
        #expect(!MenuBarView.shouldDisableSelectedIconReveal(skillPath: "/tmp/skillbar"))
        #expect(MenuBarView.shouldDisableSelectedIconReveal(skillPath: "  "))
    }

    @Test
    func recentCommandOutputCopyPayloadKeepsVisibleOutput() {
        let output = "Audit line 1\nAudit line 2\n"

        #expect(MenuBarView.recentCommandOutputCopyPayload(output) == output)
    }

    @Test
    func recentCommandOutputCopyPayloadIgnoresBlankOutput() {
        #expect(MenuBarView.recentCommandOutputCopyPayload("  \n\t ") == nil)
    }

    @Test
    func compactIconAssetOrderPrefersSmallArtwork() {
        let paths = MenuBarView.orderedIconAssetPaths(
            smallPath: "/tmp/icon-small.svg",
            largePath: "/tmp/icon-large.svg",
            preferLarge: false
        )

        #expect(paths == ["/tmp/icon-small.svg", "/tmp/icon-large.svg"])
    }

    @Test
    func largeIconAssetOrderPrefersLargeArtwork() {
        let paths = MenuBarView.orderedIconAssetPaths(
            smallPath: "/tmp/icon-small.svg",
            largePath: "/tmp/icon-large.svg",
            preferLarge: true
        )

        #expect(paths == ["/tmp/icon-large.svg", "/tmp/icon-small.svg"])
    }

    @Test
    func iconAssetOrderDeduplicatesSharedAssetPath() {
        let paths = MenuBarView.orderedIconAssetPaths(
            smallPath: "/tmp/shared.svg",
            largePath: "/tmp/shared.svg",
            preferLarge: true
        )

        #expect(paths == ["/tmp/shared.svg"])
    }

    @Test
    func compactIconSourceLabelNamesSmallArtwork() {
        let label = MenuBarView.iconSourceLabel(
            smallPath: "/tmp/icon-small.svg",
            largePath: "/tmp/icon-large.svg",
            categorySymbolName: "square.grid.2x2",
            preferLarge: false
        )

        #expect(label == "Asset: icon-small.svg")
    }

    @Test
    func largeIconSourceLabelNamesLargeArtwork() {
        let label = MenuBarView.iconSourceLabel(
            smallPath: "/tmp/icon-small.svg",
            largePath: "/tmp/icon-large.svg",
            categorySymbolName: "square.grid.2x2",
            preferLarge: true
        )

        #expect(label == "Asset: icon-large.svg")
    }

    @Test
    func iconSourceLabelFallsBackToCategorySymbol() {
        let label = MenuBarView.iconSourceLabel(
            smallPath: nil,
            largePath: nil,
            categorySymbolName: "menubar.rectangle",
            preferLarge: true
        )

        #expect(label == "Fallback: menubar.rectangle")
    }
}
