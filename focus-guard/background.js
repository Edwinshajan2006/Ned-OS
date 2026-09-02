const protectedTabs = new Map();

function rememberTab(tab) {
    if (tab.id !== undefined && tab.url && !tab.url.startsWith("chrome://")) {
        protectedTabs.set(tab.id, {
            url: tab.url,
            index: tab.index,
            pinned: tab.pinned
        });
    }
}

chrome.tabs.query({}, tabs => {
    for (const tab of tabs) {
        rememberTab(tab);
    }
});

chrome.tabs.onCreated.addListener(tab => {
    // New tabs are not allowed.
    // Immediately close them.
    if (tab.id !== undefined) {
        setTimeout(() => {
            chrome.tabs.remove(tab.id).catch(() => {});
        }, 50);
    }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.status === "complete") {
        rememberTab(tab);
    }
});

chrome.tabs.onRemoved.addListener((tabId, removeInfo) => {
    const oldTab = protectedTabs.get(tabId);

    if (!oldTab) {
        return;
    }

    protectedTabs.delete(tabId);

    // Recreate the tab that was closed.
    chrome.tabs.create({
        url: oldTab.url,
        index: oldTab.index,
        pinned: oldTab.pinned
    });
});
