function resolveMiniProgramEnvVersion() {
  try {
    if (!wx.getAccountInfoSync) {
      return 'release';
    }

    var accountInfo = wx.getAccountInfoSync();
    if (accountInfo && accountInfo.miniProgram && accountInfo.miniProgram.envVersion) {
      return accountInfo.miniProgram.envVersion;
    }
  } catch (error) {
    console.warn('读取小程序环境失败，默认按正式版处理:', error);
  }

  return 'release';
}

const CLOUD_ENV_ID = 'prod-d9grvi1o83256c2b5';
const CLOUD_SERVICE_NAME = 'animal';
const MINI_PROGRAM_ENV_VERSION = resolveMiniProgramEnvVersion();

App({
  onLaunch: function() {
    var startTime = Date.now();

    console.log('🧭 App 当前小程序环境:', MINI_PROGRAM_ENV_VERSION);

    if (!wx.cloud) {
      console.error('当前基础库不支持云开发能力');
    } else {
      try {
        wx.cloud.init({
          env: CLOUD_ENV_ID,
          traceUser: true
        });
        this.globalData.cloudInited = true;
        console.log('☁️ 云开发初始化成功:', CLOUD_ENV_ID, CLOUD_SERVICE_NAME);
      } catch (error) {
        this.globalData.cloudInited = false;
        console.error('☁️ 云开发初始化失败:', error);
      }
    }

    wx.login({
      success: function(res) {
        console.log('登录成功，code:', res.code);
      }
    });

    this.getSystemInfo();

    console.log('[Perf] App.onLaunch took ' + (Date.now() - startTime) + 'ms');
  },

  getSystemInfo: function() {
    try {
      var windowInfo = wx.getWindowInfo();
      var menuButton = wx.getMenuButtonBoundingClientRect();

      var statusBarHeight = windowInfo.statusBarHeight || 44;
      var menuButtonMargin = menuButton.top - statusBarHeight;
      var navBarHeight = menuButtonMargin * 2 + menuButton.height;
      var totalNavHeight = statusBarHeight + navBarHeight;

      this.globalData.statusBarHeight = statusBarHeight;
      this.globalData.navBarHeight = navBarHeight;
      this.globalData.totalNavHeight = totalNavHeight;
      this.globalData.windowWidth = windowInfo.windowWidth;
      this.globalData.windowHeight = windowInfo.windowHeight;

      console.log('📱 系统信息:', {
        statusBarHeight: statusBarHeight,
        navBarHeight: navBarHeight,
        totalNavHeight: totalNavHeight
      });
    } catch (e) {
      console.error('获取系统信息失败:', e);
      this.globalData.statusBarHeight = 44;
      this.globalData.navBarHeight = 44;
      this.globalData.totalNavHeight = 88;
    }
  },

  globalData: {
    userInfo: null,
    cloudInited: false,
    envVersion: MINI_PROGRAM_ENV_VERSION,
    cloudEnvId: CLOUD_ENV_ID,
    cloudServiceName: CLOUD_SERVICE_NAME,
    statusBarHeight: 44,
    navBarHeight: 44,
    totalNavHeight: 88,
    windowWidth: 375,
    windowHeight: 667
  }
});
