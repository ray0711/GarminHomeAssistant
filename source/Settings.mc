//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant.
//
// P A Abbey & J D Abbey, SomeoneOnEarth, 23 November 2023
//
//
// Description:
//
// Home Assistant settings.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Application.Properties;
using Toybox.WatchUi;
using Toybox.System;
// Battery Level Reporting
using Toybox.Background;
using Toybox.Time;

(:glance, :background)
class Settings {
    private static var mApiKey                as Lang.String  = "";
    private static var mWebhookId             as Lang.String  = "";
    private static var mApiUrl                as Lang.String  = "";
    private static var mConfigUrl             as Lang.String  = "";
    private static var mCacheConfig           as Lang.Boolean = false;
    private static var mClearCache            as Lang.Boolean = false;
    private static var mVibrate               as Lang.Boolean = false;
    private static var mAppTimeout            as Lang.Number  = 0;  // seconds
    private static var mPollDelay             as Lang.Number  = 0;  // seconds
    private static var mConfirmTimeout        as Lang.Number  = 3;  // seconds
    private static var mMenuAlignment         as Lang.Number  = WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT;
    private static var mIsBatteryLevelEnabled as Lang.Boolean = false;
    private static var mBatteryRefreshRate    as Lang.Number  = 15; // minutes
    private static var mIsApp                 as Lang.Boolean = false;
    private static var mHasService            as Lang.Boolean = false;
    // Must keep the object so it doesn't get garbage collected.
    private static var mWebhookManager        as WebhookManager or Null;

    // Called on application start and then whenever the settings are changed.
    static function update() {
        mIsApp                 = getApp().getIsApp();
        mApiKey                = Properties.getValue("api_key");
        mWebhookId             = Properties.getValue("webhook_id");
        mApiUrl                = Properties.getValue("api_url");
        mConfigUrl             = Properties.getValue("config_url");
        mCacheConfig           = Properties.getValue("cache_config");
        mClearCache            = Properties.getValue("clear_cache");
        mVibrate               = Properties.getValue("enable_vibration");
        mAppTimeout            = Properties.getValue("app_timeout");
        mPollDelay             = Properties.getValue("poll_delay");
        mConfirmTimeout        = Properties.getValue("confirm_timeout");
        mMenuAlignment         = Properties.getValue("menu_alignment");
        mIsBatteryLevelEnabled = Properties.getValue("enable_battery_level");
        mBatteryRefreshRate    = Properties.getValue("battery_level_refresh_rate");

        if (System has :ServiceDelegate) {
            mHasService = true;
        }

        // Manage this inside the application or widget only (not a glance or background service process)
        if (mIsApp) {
            if (mIsBatteryLevelEnabled and mHasService) {
                if (getWebhookId().equals("")) {
                    mWebhookManager = new WebhookManager();
                    mWebhookManager.requestWebhookId();
                }
                if ((Background.getTemporalEventRegisteredTime() == null) or
                    (Background.getTemporalEventRegisteredTime() != (mBatteryRefreshRate * 60))) {
                    Background.registerForTemporalEvent(new Time.Duration(mBatteryRefreshRate * 60)); // Convert to seconds
                }
            } else {
                // Explicitly disable the background event which persists when the application closes.
                // If !mHasService disable the Settings option as user feedback
                unsetIsBatteryLevelEnabled();
                unsetWebhookId();
            }
        }
        // System.println("Settings update(): getTemporalEventRegisteredTime() = " + Background.getTemporalEventRegisteredTime());
        // if (Background.getTemporalEventRegisteredTime() != null) {
        //     System.println("Settings update(): getTemporalEventRegisteredTime().value() = " + Background.getTemporalEventRegisteredTime().value().format("%d") + " seconds");
        // } else {
        //     System.println("Settings update(): getTemporalEventRegisteredTime() = null");
        // }
    }

    static function getApiKey() as Lang.String {
        return mApiKey;
    }

    static function getWebhookId() as Lang.String {
        return mWebhookId;
    }

    static function setWebhookId(webhookId as Lang.String) {
        mWebhookId = webhookId;
        Properties.setValue("webhook_id", mWebhookId);
    }

    static function unsetWebhookId() {
        mWebhookId = "";
        Properties.setValue("webhook_id", mWebhookId);
    }

    static function getApiUrl() as Lang.String {
        return mApiUrl;
    }

    static function getConfigUrl() as Lang.String {
        return mConfigUrl;
    }

    static function getCacheConfig() as Lang.Boolean {
        return mCacheConfig;
    }

    static function getClearCache() as Lang.Boolean {
        return mClearCache;
    }

    static function unsetClearCache() {
        mClearCache = false;
        Properties.setValue("clear_cache", mClearCache);
    }

    static function getVibrate() as Lang.Boolean {
        return mVibrate;
    }

    static function getAppTimeout() as Lang.Number {
        return mAppTimeout * 1000; // Convert to milliseconds
    }

    static function getPollDelay() as Lang.Number {
        return mPollDelay * 1000; // Convert to milliseconds
    }

    static function getConfirmTimeout() as Lang.Number {
        return mConfirmTimeout * 1000; // Convert to milliseconds
    }

    static function getMenuAlignment() as Lang.Number {
        return mMenuAlignment; // Either WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT or WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT
    }

    static function unsetIsBatteryLevelEnabled() {
        mIsBatteryLevelEnabled = false;
        Properties.setValue("enable_battery_level", mIsBatteryLevelEnabled);
        if (mHasService and (Background.getTemporalEventRegisteredTime() != null)) {
            Background.deleteTemporalEvent();
        }
    }

}
