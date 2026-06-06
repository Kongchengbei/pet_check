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

const LOCAL_SERVER_URL = 'http://localhost:5000';
const CLOUD_ENV_ID = 'prod-d9grvi1o83256c2b5';
const CLOUD_SERVICE_NAME = 'animal';
const MINI_PROGRAM_ENV_VERSION = resolveMiniProgramEnvVersion();
const USE_LOCAL_MODE = MINI_PROGRAM_ENV_VERSION === 'develop';

Page({
  data: {
    statusBarHeight: 44,
    navBarHeight: 88,

    imageList: [],
    maxImages: 9,
    movingIndex: undefined,
    isDragging: false,
    dragX: 0,
    dragY: 0,
    dragOverIndex: -1,
    dragStartX: 0,
    dragStartY: 0,

    optionList: [
      { name: "DeepSeek-R1", desc: "推理能力强，适合复杂判断", timeout: 120000 },
      { name: "DeepSeek-V3.2", desc: "速度与效果均衡，日常首选", timeout: 120000 },
      { name: "Qwen3-32B", desc: "细节理解更强，图文分析稳定", timeout: 120000 },
      { name: "GLM-4.7", desc: "中文表现好，响应速度快", timeout: 120000 },
      { name: "MiniMax-M2", desc: "轻量高效，适合快速审核", timeout: 120000 }
    ],

    quickList: [
      { name: "DeepSeek-R1", index: 0 },
      { name: "Qwen3-Next", index: 2 }
    ],

    optionIndex: 0,
    tempIndex: 0,
    showPicker: false,
    toastVisible: false,
    toastText: '',
    toastType: 'info',
    toastSymbol: 'i',
    loadingPopupVisible: false,
    deleteModalVisible: false,
    deleteTargetIndex: -1,
    errorModalVisible: false,
    errorTitle: '',
    errorMessage: '',
    errorConfirmText: '',
    errorCancelText: '',
    errorShowCancel: true,
    resultContent: null,
    resultRawText: '',
    usedModel: '',
    isLoading: false,
    loadingText: '准备中',

    localServerUrl: LOCAL_SERVER_URL,
    runMode: USE_LOCAL_MODE ? '本地模式' : '云托管模式'
  },

  loadingTimer: null,
  pollingTimer: null,
  longPressTimer: null,
  toastTimer: null,
  errorConfirmAction: null,

  onLoad: function() {
    var optionList = this.data.optionList.map(function(item, index) {
      if (index === 2) {
        return Object.assign({}, item, { displayName: 'Qwen3-Next' });
      }
      return item;
    });

    this.initNavBar();
    this.setData({ optionList: optionList });
    console.log('页面加载完成，共有', this.data.optionList.length, '个模型可选');
    console.log('🧭 当前小程序环境:', MINI_PROGRAM_ENV_VERSION);
    console.log('🔧 当前运行模式:', this.data.runMode);
    console.log('🌐 当前接口标识:', this.getApiBaseUrl());
  },

  initNavBar: function() {
    try {
      var windowInfo = wx.getWindowInfo();
      var menuButton = wx.getMenuButtonBoundingClientRect();

      var statusBarHeight = windowInfo.statusBarHeight || 44;
      var menuButtonMargin = menuButton.top - statusBarHeight;
      var navContentHeight = menuButtonMargin * 2 + menuButton.height;
      var navBarHeight = statusBarHeight + navContentHeight;

      this.setData({
        statusBarHeight: statusBarHeight,
        navBarHeight: navBarHeight
      });

    } catch (e) {
      console.error('获取导航栏高度失败:', e);
      this.setData({
        statusBarHeight: 44,
        navBarHeight: 88
      });
    }
  },

  showToastCard: function(text, type, duration) {
    var symbolMap = {
      success: '\u2713',
      warning: '!',
      danger: '\u00d7',
      info: 'i'
    };

    if (this.toastTimer) {
      clearTimeout(this.toastTimer);
      this.toastTimer = null;
    }

    this.setData({
      toastVisible: true,
      toastText: text,
      toastType: type || 'info',
      toastSymbol: symbolMap[type] || symbolMap.info
    });

    this.toastTimer = setTimeout(() => {
      this.setData({ toastVisible: false });
      this.toastTimer = null;
    }, duration || 1800);
  },

  getApiBaseUrl: function() {
    return USE_LOCAL_MODE
      ? this.data.localServerUrl
      : 'cloud://' + CLOUD_ENV_ID + '/' + CLOUD_SERVICE_NAME;
  },

  buildNetworkError: function(err, fallbackMessage) {
    var rawMessage = '';

    if (err) {
      rawMessage = err.errMsg || err.message || '';
    }

    rawMessage = String(rawMessage || '');

    var lowerMessage = rawMessage.toLowerCase();
    if (lowerMessage.indexOf('env not exists') !== -1) {
      return {
        code: 'CLOUD_ENV_ERROR',
        message: '云开发环境不存在或未关联',
        detail: rawMessage
      };
    }

    if (lowerMessage.indexOf('not in domain list') !== -1) {
      return {
        code: 'DOMAIN_NOT_ALLOWED',
        message: '当前域名未加入小程序合法域名',
        detail: rawMessage
      };
    }

    if (
      lowerMessage.indexOf('ssl') !== -1 ||
      lowerMessage.indexOf('certificate') !== -1 ||
      lowerMessage.indexOf('tls') !== -1
    ) {
      return {
        code: 'TLS_ERROR',
        message: 'HTTPS证书校验失败',
        detail: rawMessage
      };
    }

    if (lowerMessage.indexOf('timeout') !== -1) {
      return {
        code: 'TIMEOUT',
        message: '网络请求超时',
        detail: rawMessage
      };
    }

    return {
      code: 'NETWORK_ERROR',
      message: fallbackMessage,
      detail: rawMessage
    };
  },

  describeAuditError: function(error) {
    var errorInfo = error || {};
    var errorTitle = '请求失败';
    var errorMessage = errorInfo.message || '审核失败，请稍后重试';
    var rawDetail = errorInfo.detail ? '\n\n原始错误：' + errorInfo.detail : '';

    if (errorInfo.code === 'SERVICE_UNAVAILABLE') {
      errorTitle = '服务不可用';
      errorMessage = USE_LOCAL_MODE
        ? '本地服务未启动，请确认后端已运行'
        : '云托管服务暂不可用，请稍后重试';
    } else if (errorInfo.code === 'CLOUD_ENV_ERROR') {
      errorTitle = '云环境异常';
      errorMessage =
        '请确认小程序已绑定云开发环境：\n' +
        CLOUD_ENV_ID +
        '\n服务名：' +
        CLOUD_SERVICE_NAME +
        rawDetail;
    } else if (errorInfo.code === 'DOMAIN_NOT_ALLOWED') {
      errorTitle = '域名未配置';
      errorMessage =
        '当前接入方式仍触发了合法域名校验，请确认体验版已更新到云托管调用版本。' +
        rawDetail;
    } else if (errorInfo.code === 'TLS_ERROR') {
      errorTitle = '证书异常';
      errorMessage = '请确认云托管 HTTPS 链路和证书配置有效。' + rawDetail;
    } else if (errorInfo.code === 'NETWORK_ERROR') {
      errorTitle = '网络异常';
      errorMessage = USE_LOCAL_MODE
        ? '无法连接本地服务，请检查地址和端口'
        : '无法连接云托管服务，请检查环境、服务名和网络后重试';

      if (rawDetail) {
        errorMessage += rawDetail;
      }
    } else if (errorInfo.code === 'TIMEOUT') {
      errorTitle = '处理超时';
      errorMessage = '任务执行时间较长，请稍后重试';
      if (rawDetail) {
        errorMessage += rawDetail;
      }
    }

    return {
      title: errorTitle,
      message: errorMessage
    };
  },

  openDeleteModal: function(index) {
    this.setData({
      deleteModalVisible: true,
      deleteTargetIndex: index
    });
  },

  closeDeleteModal: function() {
    this.setData({
      deleteModalVisible: false,
      deleteTargetIndex: -1
    });
  },

  confirmDeleteModal: function() {
    var index = this.data.deleteTargetIndex;

    if (index < 0) {
      this.closeDeleteModal();
      return;
    }

    var newList = this.data.imageList.filter(function(item, i) {
      return i !== index;
    });

    this.setData({
      imageList: newList,
      resultContent: newList.length === 0 ? null : this.data.resultContent,
      resultRawText: newList.length === 0 ? '' : this.data.resultRawText,
      usedModel: newList.length === 0 ? '' : this.data.usedModel,
      deleteModalVisible: false,
      deleteTargetIndex: -1
    });

    wx.vibrateShort({ type: 'heavy' });
    this.showToastCard('\u5df2\u5220\u9664', 'warning', 1600);
  },

  openErrorModal: function(title, message, options) {
    var modalOptions = options || {};

    this.errorConfirmAction = modalOptions.onConfirm || null;
    this.setData({
      errorModalVisible: true,
      errorTitle: title || '\u63d0\u793a',
      errorMessage: message || '',
      errorConfirmText: modalOptions.confirmText || '\u77e5\u9053\u4e86',
      errorCancelText: modalOptions.cancelText || '\u53d6\u6d88',
      errorShowCancel: modalOptions.showCancel !== false
    });
  },

  closeErrorModal: function() {
    this.errorConfirmAction = null;
    this.setData({
      errorModalVisible: false,
      errorTitle: '',
      errorMessage: '',
      errorConfirmText: '',
      errorCancelText: '',
      errorShowCancel: true
    });
  },

  confirmErrorModal: function() {
    var action = this.errorConfirmAction;
    this.closeErrorModal();
    if (typeof action === 'function') {
      action();
    }
  },

  openPicker: function() {
    this.setData({
      showPicker: !this.data.showPicker,
      tempIndex: this.data.optionIndex
    });
  },

  closePicker: function() {
    this.setData({ showPicker: false });
  },

  selectOption: function(e) {
    var index = e.currentTarget.dataset.index;
    this.setData({
      optionIndex: index,
      tempIndex: index
    });
    wx.vibrateShort({ type: 'light' });
  },

  chooseImage: function(e) {
    wx.vibrateShort({ type: 'light' });
    var that = this;
    var currentIndex = e.currentTarget.dataset.index;
    var isReplace = currentIndex !== undefined;

    var maxCount = isReplace ? 1 : (this.data.maxImages - this.data.imageList.length);

    wx.chooseMedia({
      count: maxCount,
      mediaType: ['image'],
      sourceType: ['album', 'camera'],
      success: function(res) {
        var tempFiles = res.tempFiles.map(function(file) {
          return {
            path: file.tempFilePath,
            id: Date.now() + Math.random()
          };
        });

        if (isReplace) {
          var newList = that.data.imageList.slice();
          newList[currentIndex] = tempFiles[0];
          that.setData({ imageList: newList });
          wx.vibrateShort({ type: 'medium' });
        } else {
          that.setData({
            imageList: that.data.imageList.concat(tempFiles)
          });
          wx.vibrateShort({ type: 'heavy' });
        }

        wx.showToast({
          title: isReplace ? '已替换图片' : '已添加图片',
          icon: 'success',
          duration: 1500
        });
      },
      fail: function(err) {
        console.error('选择图片失败:', err);
      }
    });
  },

  removeImage: function(e) {
    wx.vibrateShort({ type: 'medium' });
    var that = this;
    var index = parseInt(e.currentTarget.dataset.index);

    wx.showModal({
      title: '删除图片',
      content: '确定删除这张图片吗？',
      confirmText: '删除',
      cancelText: '取消',
      confirmColor: '#EF5350',
      success: function(res) {
        if (res.confirm) {
          var newList = that.data.imageList.filter(function(item, i) {
            return i !== index;
          });

          that.setData({
            imageList: newList,
            resultContent: newList.length === 0 ? null : that.data.resultContent,
            resultRawText: newList.length === 0 ? '' : that.data.resultRawText,
            usedModel: newList.length === 0 ? '' : that.data.usedModel
          });

          wx.vibrateShort({ type: 'heavy' });
          wx.showToast({ title: '已删除', icon: 'none' });
        }
      }
    });
  },

  onDragStart: function(e) {
    var that = this;
    if (this.data.imageList.length < 2) {
      return;
    }

    var index = e.currentTarget.dataset.index;
    var touch = e.touches[0];

    this.setData({
      dragStartX: touch.pageX,
      dragStartY: touch.pageY
    });

    this.longPressTimer = setTimeout(function() {
      wx.vibrateShort({ type: 'medium' });

      that.setData({
        isDragging: true,
        movingIndex: index,
        dragX: touch.pageX,
        dragY: touch.pageY,
        imageList: that.data.imageList.map(function(item, i) {
          return Object.assign({}, item, { moving: i === index });
        })
      });
    }, 500);
  },

  onDragMove: function(e) {
    var that = this;

    if (!this.data.isDragging && this.longPressTimer) {
      var touch = e.touches[0];
      var deltaX = Math.abs(touch.pageX - this.data.dragStartX);
      var deltaY = Math.abs(touch.pageY - this.data.dragStartY);

      if (deltaX > 10 || deltaY > 10) {
        clearTimeout(this.longPressTimer);
        this.longPressTimer = null;
        return;
      }
    }

    if (!this.data.isDragging) {
      return;
    }

    var touch = e.touches[0];

    this.setData({
      dragX: touch.pageX,
      dragY: touch.pageY
    });

    var query = wx.createSelectorQuery();
    query.selectAll('.grid-item').boundingClientRect();
    query.exec(function(res) {
      if (!res || !res[0]) return;

      var rects = res[0];
      var overIndex = -1;

      for (var i = 0; i < rects.length - (that.data.imageList.length < that.data.maxImages ? 1 : 0); i++) {
        var rect = rects[i];
        if (touch.pageX >= rect.left && touch.pageX <= rect.right &&
            touch.pageY >= rect.top && touch.pageY <= rect.bottom) {
          overIndex = i;
          break;
        }
      }

      if (overIndex !== that.data.dragOverIndex && overIndex !== -1) {
        that.setData({ dragOverIndex: overIndex });

        if (overIndex !== that.data.movingIndex) {
          var fromIndex = that.data.movingIndex;
          var newList = that.data.imageList.slice();
          var item = newList[fromIndex];

          newList.splice(fromIndex, 1);
          newList.splice(overIndex, 0, item);

          that.setData({
            imageList: newList.map(function(img, idx) {
              return Object.assign({}, img, { moving: idx === overIndex });
            }),
            movingIndex: overIndex
          });

          wx.vibrateShort({ type: 'light' });
        }
      }
    });
  },

  onDragEnd: function(e) {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }

    if (!this.data.isDragging) {
      var touch = e.changedTouches && e.changedTouches[0];
      if (touch) {
        var query = wx.createSelectorQuery();
        query.selectAll('.delete-icon').boundingClientRect();
        query.exec((res) => {
          if (res && res[0]) {
            var isDeleteBtn = res[0].some(rect => {
              return touch.pageX >= rect.left && touch.pageX <= rect.right &&
                     touch.pageY >= rect.top && touch.pageY <= rect.bottom;
            });

            if (!isDeleteBtn && this.data.imageList.length >= 2) {
              this.chooseImage(e);
            }
          }
        });
      }
      return;
    }

    this.setData({
      isDragging: false,
      movingIndex: undefined,
      dragOverIndex: -1,
      imageList: this.data.imageList.map(function(item) {
        delete item.moving;
        return item;
      })
    });

    wx.vibrateShort({ type: 'medium' });
  },

  openPicker: function() {
    this.setData({
      showPicker: !this.data.showPicker,
      tempIndex: this.data.optionIndex
    });
    wx.vibrateShort({ type: 'light' });
  },

  closePicker: function() {
    this.setData({ showPicker: false });
  },

  selectOption: function(e) {
    var index = Number(e.currentTarget.dataset.index);
    this.setData({
      tempIndex: index,
      optionIndex: index,
      showPicker: false
    });
  },

  confirmPicker: function() {
    this.setData({
      optionIndex: this.data.tempIndex,
      showPicker: false
    });

    wx.showToast({ title: '已切换模型', icon: 'success' });
    console.log('确认选择模型:', this.data.optionList[this.data.tempIndex].name);
  },

  quickSelect: function(e) {
    var index = e.currentTarget.dataset.index;
    this.setData({ optionIndex: index });
    wx.vibrateShort({ type: 'light' });
    console.log('快捷选择模型:', this.data.optionList[index].name);
  },

  showLoadingWithProgress: function() {
    var that = this;
    var seconds = 0;
    var modelName = this.data.optionList[this.data.optionIndex].name;

    wx.showLoading({ title: '正在准备...', mask: true });

    if (this.loadingTimer) {
      clearInterval(this.loadingTimer);
    }

    this.loadingTimer = setInterval(function() {
      seconds++;

      var title = '';
      if (seconds < 3) {
        title = '正在上传图片...';
      } else if (seconds < 8) {
        title = '正在创建任务...';
      } else if (seconds < 20) {
        title = modelName + ' 分析中...';
      } else if (seconds < 40) {
        title = '处理中 ' + seconds + 's';
      } else if (seconds < 90) {
        title = '任务较复杂 ' + seconds + 's';
      } else {
        title = '请稍候 ' + seconds + 's';
      }

      wx.showLoading({ title: title, mask: true });
      that.setData({ loadingText: title });

    }, 1000);
  },

  hideLoadingWithProgress: function() {
    if (this.loadingTimer) {
      clearInterval(this.loadingTimer);
      this.loadingTimer = null;
    }
    if (this.pollingTimer) {
      clearInterval(this.pollingTimer);
      this.pollingTimer = null;
    }
    wx.hideLoading();
  },

  onButtonATap: function() {
    var that = this;

    if (this.data.imageList.length === 0) {
      wx.showToast({ title: '请先上传图片', icon: 'none', duration: 2000 });
      return;
    }

    if (this.data.isLoading) {
      return;
    }

    wx.vibrateShort({ type: 'heavy' });

    this.setData({ isLoading: true });
    this.showLoadingWithProgress();

    var imageList = this.data.imageList;
    var modelName = this.data.optionList[this.data.optionIndex].name;

    this.CheckOut(imageList, modelName)
      .then(function(markdownResult) {
        var parsedContent = that.parseMarkdown(markdownResult);

        that.setData({
          resultContent: parsedContent,
          resultRawText: markdownResult,
          usedModel: modelName,
          isLoading: false
        });

        that.hideLoadingWithProgress();

        wx.showToast({ title: '审核完成', icon: 'success' });
        wx.vibrateShort({ type: 'medium' });

        console.log('审核成功 - 使用模型:', modelName);
      })
      .catch(function(error) {
        console.error('审核失败:', error);

        that.setData({ isLoading: false });
        that.hideLoadingWithProgress();

        var errorInfo = that.describeAuditError(error);

        wx.showModal({
          title: errorInfo.title,
          content: errorInfo.message,
          showCancel: true,
          cancelText: '取消',
          confirmText: '重试',
          success: function(res) {
            if (res.confirm) {
              that.onButtonATap();
            }
          }
        });
      });
  },

  uploadImage: function(imagePath) {
    var that = this;

    return new Promise(function(resolve, reject) {
      if (USE_LOCAL_MODE) {
        console.log('📤️ 开始上传图片到本地服务器...');

        wx.uploadFile({
          url: that.data.localServerUrl + '/api/upload',
          filePath: imagePath,
          name: 'file',
          success: function(res) {
            console.log('上传响应:', res);

            if (res.statusCode === 200) {
              try {
                var data = JSON.parse(res.data);
                if (data.success) {
                  console.log('✅ 图片上传成功:', data.data.url);
                  resolve(data.data.url);
                } else {
                  reject({ code: 'UPLOAD_FAILED', message: data.message || '上传失败' });
                }
              } catch (e) {
                reject({ code: 'PARSE_ERROR', message: '解析响应失败' });
              }
            } else {
              reject({ code: 'UPLOAD_FAILED', message: '服务器响应异常: ' + res.statusCode });
            }
          },
          fail: function(err) {
            console.error('❌ 图片上传失败:', err);
            reject(that.buildNetworkError(err, '无法连接到本地服务器'));
          }
        });
        return;
      }

      var timestamp = Date.now();
      var randomStr = Math.random().toString(36).substring(2, 8);
      var cloudPath = 'audit-images/' + timestamp + '_' + randomStr + '.jpg';

      console.log('📤️ 开始上传图片到云开发存储...');

      wx.cloud.uploadFile({
        cloudPath: cloudPath,
        filePath: imagePath,
        success: function(uploadRes) {
          console.log('✅ 图片上传成功:', uploadRes.fileID);

          wx.cloud.getTempFileURL({
            fileList: [uploadRes.fileID],
            success: function(urlRes) {
              if (urlRes.fileList && urlRes.fileList[0] && urlRes.fileList[0].tempFileURL) {
                resolve(urlRes.fileList[0].tempFileURL);
              } else {
                reject({ code: 'URL_FAILED', message: '获取图片链接失败' });
              }
            },
            fail: function(err) {
              console.error('❌ 获取临时链接失败:', err);
              reject(that.buildNetworkError(err, '获取图片链接失败'));
            }
          });
        },
        fail: function(err) {
          console.error('❌ 图片上传到云开发失败:', err);
          reject(that.buildNetworkError(err, '图片上传失败'));
        }
      });
    });
  },

  CheckOut: function(imageList, modelName) {
    var that = this;

    console.log('=== CheckOut 函数被调用 (' + this.data.runMode + ') ===');
    console.log('图片数量:', imageList.length);
    console.log('使用模型:', modelName);

    var uploadPromises = imageList.map(function(img) {
      return that.uploadImage(img.path);
    });

    return Promise.all(uploadPromises)
      .then(function(fileUrls) {
        console.log('✅ 所有图片上传完成,共', fileUrls.length, '张');
        console.log('🖼 图片URLs:', fileUrls);
        console.log('📮 提交审核任务...');
        return that.submitAuditTask(fileUrls, modelName);
      })
      .then(function(submitResult) {
        if (!submitResult.taskId) {
          throw { code: 'SUBMIT_FAILED', message: '任务提交失败' };
        }

        console.log('✅ 任务已提交, taskId:', submitResult.taskId);
        console.log('🔄 开始轮询任务结果...');

        return that.pollTaskResult(submitResult.taskId);
      })
      .then(function(result) {
        console.log('=== Model审核结果 ===');
        console.log(result);

        var currentTime = new Date().toLocaleString('zh-CN');
        var markdownReport = '# 宠粮审核报告\n\n' +
          '## 基本信息\n\n' +
          '- 审核时间: ' + currentTime + '\n' +
          '- 使用模型: ' + modelName + '\n' +
          '- 图片数量: ' + imageList.length + ' 张\n' +
          '- 运行模式: ' + that.data.runMode + '\n\n' +
          '---\n\n' +
          '## 审核结论\n\n' +
          result + '\n\n' +
          '---\n\n' +
          '> 报告由 ' + modelName + ' 生成，仅供参考。';

        return markdownReport;
      });
  },

  submitAuditTask: function(fileUrl, modelName) {
    var that = this;

    return new Promise(function(resolve, reject) {
      console.log('📮 提交任务到后端...');

      if (USE_LOCAL_MODE) {
        wx.request({
          url: that.data.localServerUrl + '/api/audit',
          method: 'POST',
          header: {
            'content-type': 'application/json'
          },
          data: {
            fileURLs: Array.isArray(fileUrl) ? fileUrl : [fileUrl],
            model: modelName,
            level: 3
          },
          timeout: 30000,
          success: function(res) {
            console.log('✅ 任务提交响应:', res.statusCode);

            if (res.statusCode === 200 && res.data && res.data.success) {
              resolve({
                taskId: res.data.data.taskId,
                status: res.data.data.status
              });
            } else {
              reject({
                code: 'SUBMIT_FAILED',
                message: (res.data && res.data.message) || '任务提交失败'
              });
            }
          },
          fail: function(err) {
            console.error('❌ 任务提交失败:', err);
            reject(that.buildNetworkError(err, '任务提交时网络连接失败'));
          }
        });
        return;
      }

      wx.cloud.callContainer({
        config: {
          env: CLOUD_ENV_ID
        },
        path: '/api/audit',
        method: 'POST',
        header: {
          'X-WX-SERVICE': CLOUD_SERVICE_NAME,
          'content-type': 'application/json'
        },
        data: {
          fileURLs: Array.isArray(fileUrl) ? fileUrl : [fileUrl],
          model: modelName,
          level: 3
        },
        timeout: 30000,
        success: function(res) {
          console.log('✅ 云托管任务提交响应:', res.statusCode);

          if (res.statusCode === 200 && res.data && res.data.success) {
            resolve({
              taskId: res.data.data.taskId,
              status: res.data.data.status
            });
          } else {
            reject({
              code: 'SUBMIT_FAILED',
              message: (res.data && res.data.message) || '任务提交失败'
            });
          }
        },
        fail: function(err) {
          console.error('❌ 云托管任务提交失败:', err);
          reject(that.buildNetworkError(err, '云托管任务提交失败'));
        }
      });
    });
  },

  pollTaskResult: function(taskId) {
    var that = this;

    return new Promise(function(resolve, reject) {
      var MAX_POLL_TIME = 180000;
      var POLL_INTERVAL = 7000;
      var startTime = Date.now();
      var pollCount = 0;

      var poll = function() {
        pollCount++;

        if (Date.now() - startTime > MAX_POLL_TIME) {
          if (that.pollingTimer) {
            clearInterval(that.pollingTimer);
            that.pollingTimer = null;
          }
          reject({ code: 'TIMEOUT', message: '任务处理超时,请稍后重试' });
          return;
        }

        console.log('🔍 轮询任务结果 (第 ' + pollCount + ' 次)...');
        if (USE_LOCAL_MODE) {
          wx.request({
            url: that.data.localServerUrl + '/api/task/' + taskId,
            method: 'GET',
            timeout: 10000,
            success: function(res) {
              that.handlePollResponse(res, resolve, reject);
            },
            fail: function(err) {
              console.warn('⚠️ 轮询请求失败,继续重试:', err);
            }
          });
          return;
        }

        wx.cloud.callContainer({
          config: {
            env: CLOUD_ENV_ID
          },
          path: '/api/task/' + taskId,
          method: 'GET',
          header: {
            'X-WX-SERVICE': CLOUD_SERVICE_NAME
          },
          timeout: 10000,
          success: function(res) {
            that.handlePollResponse(res, resolve, reject);
          },
          fail: function(err) {
            console.warn('⚠️ 云托管轮询失败,继续重试:', err);
          }
        });
      };

      poll();
      that.pollingTimer = setInterval(poll, POLL_INTERVAL);
    });
  },

  handlePollResponse: function(res, resolve, reject) {
    var that = this;

    if (res.statusCode === 200 && res.data && res.data.success) {
      var data = res.data.data;

      if (data.status === 'completed') {
        console.log('✅ 任务处理完成');
        if (that.pollingTimer) {
          clearInterval(that.pollingTimer);
          that.pollingTimer = null;
        }
        resolve(data.result);

      } else if (data.status === 'failed') {
        console.error('❌ 任务处理失败:', data.message);
        if (that.pollingTimer) {
          clearInterval(that.pollingTimer);
          that.pollingTimer = null;
        }
        reject({ code: 'TASK_FAILED', message: data.message || '审核失败' });

      } else {
        console.log('🔄 任务状态: ' + data.status);
      }
    } else if (res.statusCode === 404) {
      if (that.pollingTimer) {
        clearInterval(that.pollingTimer);
        that.pollingTimer = null;
      }
      reject({ code: 'TASK_NOT_FOUND', message: '任务不存在或已过期' });
    }
  },

  parseMarkdown: function(markdown) {
    if (!markdown || typeof markdown !== 'string') {
      return [{ type: 'paragraph', content: '暂无内容' }];
    }

    var lines = markdown.split('\n');
    var result = [];
    var inCodeBlock = false;
    var codeBlockContent = [];
    var codeBlockLang = '';

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var trimmedLine = line.trim();

      if (trimmedLine.indexOf('```') === 0) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          codeBlockLang = trimmedLine.substring(3).trim();
          codeBlockContent = [];
        } else {
          inCodeBlock = false;
          result.push({
            type: 'code-block',
            language: codeBlockLang,
            content: codeBlockContent.join('\n')
          });
          codeBlockContent = [];
          codeBlockLang = '';
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockContent.push(line);
        continue;
      }

      if (!trimmedLine) {
        continue;
      }

      if (trimmedLine === '---' || trimmedLine === '***' || trimmedLine === '___') {
        result.push({ type: 'hr' });
        continue;
      }

      if (trimmedLine.indexOf('#### ') === 0) {
        result.push({ type: 'h4', content: this.cleanMarkdownText(trimmedLine.substring(5)) });
        continue;
      }
      if (trimmedLine.indexOf('### ') === 0) {
        result.push({ type: 'h3', content: this.cleanMarkdownText(trimmedLine.substring(4)) });
        continue;
      }
      if (trimmedLine.indexOf('## ') === 0) {
        result.push({ type: 'h2', content: this.cleanMarkdownText(trimmedLine.substring(3)) });
        continue;
      }
      if (trimmedLine.indexOf('# ') === 0) {
        result.push({ type: 'h1', content: this.cleanMarkdownText(trimmedLine.substring(2)) });
        continue;
      }

      if (trimmedLine.indexOf('- ') === 0) {
        result.push({ type: 'list-item', content: this.cleanMarkdownText(trimmedLine.substring(2)) });
        continue;
      }
      if (trimmedLine.indexOf('* ') === 0) {
        result.push({ type: 'list-item', content: this.cleanMarkdownText(trimmedLine.substring(2)) });
        continue;
      }

      var orderedMatch = trimmedLine.match(/^(\d+)\.\s+(.*)$/);
      if (orderedMatch) {
        result.push({
          type: 'ordered-item',
          order: orderedMatch[1],
          content: this.cleanMarkdownText(orderedMatch[2])
        });
        continue;
      }

      if (trimmedLine.indexOf('> ') === 0) {
        var quoteContent = trimmedLine.substring(2);
        result.push({ type: 'blockquote', content: this.cleanMarkdownText(quoteContent) });
        continue;
      }

      if (trimmedLine.indexOf('✅') === 0 || trimmedLine.indexOf('✓') === 0) {
        result.push({ type: 'success', content: this.cleanMarkdownText(trimmedLine.substring(1)) });
        continue;
      }
      if (trimmedLine.indexOf('❌') === 0 || trimmedLine.indexOf('✗') === 0) {
        result.push({ type: 'error', content: this.cleanMarkdownText(trimmedLine.substring(1)) });
        continue;
      }
      if (trimmedLine.indexOf('⚠️') === 0 || trimmedLine.indexOf('⚠') === 0) {
        result.push({ type: 'warning', content: this.cleanMarkdownText(trimmedLine.substring(1)) });
        continue;
      }
      if (trimmedLine.indexOf('💡') === 0 || trimmedLine.indexOf('ℹ') === 0) {
        result.push({ type: 'info', content: this.cleanMarkdownText(trimmedLine.substring(1)) });
        continue;
      }

      var paragraphType = 'paragraph';
      if (trimmedLine.indexOf('**') !== -1 || trimmedLine.indexOf('__') !== -1) {
        paragraphType = 'bold-paragraph';
      }

      result.push({
        type: paragraphType,
        content: this.cleanMarkdownText(trimmedLine)
      });
    }

    return result;
  },

  cleanMarkdownText: function(text) {
    if (!text) return '';

    return text
      .replace(/\*\*(.+?)\*\*/g, '$1')
      .replace(/__(.+?)__/g, '$1')
      .replace(/\*(.+?)\*/g, '$1')
      .replace(/_(.+?)_/g, '$1')
      .replace(/`(.+?)`/g, '$1')
      .replace(/\[(.+?)\]\(.+?\)/g, '$1');
  },

  copyResult: function() {
    var that = this;

    if (!this.data.resultRawText) {
      this.showToastCard('\u6682\u65e0\u53ef\u590d\u5236\u5185\u5bb9', 'warning', 1800);
      return;
    }

    wx.setClipboardData({
      data: this.data.resultRawText,
      success: function() {
        wx.vibrateShort({ type: 'light' });
      },
      fail: function() {
        that.showToastCard('\u590d\u5236\u5931\u8d25', 'danger', 1800);
      }
    });
  },

  shareResult: function() {
    wx.showToast({
      title: '请使用右上角分享',
      icon: 'none',
      duration: 2000
    });
  },

  chooseImage: function(e) {
    wx.vibrateShort({ type: 'light' });
    var that = this;
    var currentIndex = e.currentTarget.dataset.index;
    var isReplace = currentIndex !== undefined;
    var maxCount = isReplace ? 1 : (this.data.maxImages - this.data.imageList.length);

    wx.chooseMedia({
      count: maxCount,
      mediaType: ['image'],
      sourceType: ['album', 'camera'],
      success: function(res) {
        var tempFiles = res.tempFiles.map(function(file) {
          return {
            path: file.tempFilePath,
            id: Date.now() + Math.random()
          };
        });

        if (isReplace) {
          var newList = that.data.imageList.slice();
          newList[currentIndex] = tempFiles[0];
          that.setData({ imageList: newList });
          wx.vibrateShort({ type: 'medium' });
        } else {
          that.setData({
            imageList: that.data.imageList.concat(tempFiles)
          });
          wx.vibrateShort({ type: 'heavy' });
        }

        that.showToastCard(
          isReplace ? '\u5df2\u66ff\u6362\u56fe\u7247' : '\u5df2\u6dfb\u52a0\u56fe\u7247',
          'success',
          1500
        );
      },
      fail: function(err) {
        console.error('chooseImage failed:', err);
      }
    });
  },

  removeImage: function(e) {
    wx.vibrateShort({ type: 'medium' });
    var index = parseInt(e.currentTarget.dataset.index);
    this.openDeleteModal(index);
  },

  confirmPicker: function() {
    this.setData({
      optionIndex: this.data.tempIndex,
      showPicker: false
    });

    this.showToastCard('\u5df2\u5207\u6362\u6a21\u578b', 'success', 1500);
    console.log('confirm model:', this.data.optionList[this.data.tempIndex].name);
  },

  showLoadingWithProgress: function() {
    var that = this;
    var seconds = 0;
    var modelName = this.data.optionList[this.data.optionIndex].name;

    this.setData({
      loadingPopupVisible: true,
      loadingText: '\u6b63\u5728\u51c6\u5907...'
    });

    if (this.loadingTimer) {
      clearInterval(this.loadingTimer);
    }

    this.loadingTimer = setInterval(function() {
      seconds++;

      var title = '';
      if (seconds < 3) {
        title = '\u6b63\u5728\u4e0a\u4f20\u56fe\u7247...';
      } else if (seconds < 8) {
        title = '\u6b63\u5728\u521b\u5efa\u4efb\u52a1...';
      } else if (seconds < 20) {
        title = modelName + ' \u5206\u6790\u4e2d...';
      } else if (seconds < 40) {
        title = '\u5904\u7406\u4e2d ' + seconds + 's';
      } else if (seconds < 90) {
        title = '\u4efb\u52a1\u8f83\u590d\u6742 ' + seconds + 's';
      } else {
        title = '\u8bf7\u7a0d\u5019 ' + seconds + 's';
      }

      that.setData({ loadingText: title });
    }, 1000);
  },

  hideLoadingWithProgress: function() {
    if (this.loadingTimer) {
      clearInterval(this.loadingTimer);
      this.loadingTimer = null;
    }
    if (this.pollingTimer) {
      clearInterval(this.pollingTimer);
      this.pollingTimer = null;
    }

    this.setData({ loadingPopupVisible: false });
  },

  onButtonATap: function() {
    var that = this;

    if (this.data.imageList.length === 0) {
      this.showToastCard('\u8bf7\u5148\u4e0a\u4f20\u56fe\u7247', 'warning', 2000);
      return;
    }

    if (this.data.isLoading) {
      return;
    }

    wx.vibrateShort({ type: 'heavy' });

    this.setData({ isLoading: true });
    this.showLoadingWithProgress();

    var imageList = this.data.imageList;
    var modelName = this.data.optionList[this.data.optionIndex].name;

    this.CheckOut(imageList, modelName)
      .then(function(markdownResult) {
        var parsedContent = that.parseMarkdown(markdownResult);

        that.setData({
          resultContent: parsedContent,
          resultRawText: markdownResult,
          usedModel: modelName,
          isLoading: false
        });

        that.hideLoadingWithProgress();
        that.showToastCard('\u5ba1\u6838\u5b8c\u6210', 'success', 1800);
        wx.vibrateShort({ type: 'medium' });
      })
      .catch(function(error) {
        console.error('audit failed:', error);

        that.setData({ isLoading: false });
        that.hideLoadingWithProgress();

        var errorInfo = that.describeAuditError(error);

        that.openErrorModal(errorInfo.title, errorInfo.message, {
          showCancel: true,
          cancelText: '\u53d6\u6d88',
          confirmText: '\u91cd\u8bd5',
          onConfirm: function() {
            that.onButtonATap();
          }
        });
      });
  },

  copyResult: function() {
    var that = this;

    if (!this.data.resultRawText) {
      this.showToastCard('\u6682\u65e0\u53ef\u590d\u5236\u5185\u5bb9', 'warning', 1800);
      return;
    }

    wx.setClipboardData({
      data: this.data.resultRawText,
      success: function() {
        wx.vibrateShort({ type: 'light' });
      },
      fail: function() {
        that.showToastCard('\u590d\u5236\u5931\u8d25', 'danger', 1800);
      }
    });
  },

  shareResult: function() {
    this.showToastCard('\u8bf7\u4f7f\u7528\u53f3\u4e0a\u89d2\u5206\u4eab', 'info', 2000);
  },

  onShareAppMessage: function() {
    return {
      title: '宠粮审核助手',
      path: '/pages/index/index',
      imageUrl: this.data.imageList.length > 0 ? this.data.imageList[0].path : ''
    };
  },

  onShareAppMessage: function() {
    return {
      title: '\u5ba0\u6807\u901f\u9274',
      path: '/pages/index/index',
      imageUrl: this.data.imageList.length > 0 ? this.data.imageList[0].path : ''
    };
  },

  openPicker: function() {
    this.setData({
      showPicker: !this.data.showPicker,
      tempIndex: this.data.optionIndex
    });
  },

  quickSelect: function(e) {
    var index = Number(e.currentTarget.dataset.index);

    if (this.data.optionIndex === index && !this.data.showPicker) {
      return;
    }

    this.setData({
      optionIndex: index,
      tempIndex: index,
      showPicker: false
    });
    console.log('quick select model:', this.data.optionList[index].name);
  },

  onUnload: function() {
    this.hideLoadingWithProgress();
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }
    if (this.toastTimer) {
      clearTimeout(this.toastTimer);
      this.toastTimer = null;
    }
    this.errorConfirmAction = null;
  }
});
