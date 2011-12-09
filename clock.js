var Clock;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
Clock = (function() {
  function Clock() {
    this.config = {
      age: 25,
      gender: 'male',
      bmi: 25,
      expectancy: 75,
      hue: 195,
      checkcolors: false,
      lightlabels: true,
      smoker: false,
      reverse: false,
      rotate: false,
      rotate_context: 'minute',
      show_labels: true,
      show_percentage: false,
      show_grid: false,
      line_width: 50
    };
    this.contexts_available = ['second', 'minute', 'hour', 'day', 'week', 'month', 'year', 'decade', 'life', 'century', 'millenium', 'earth'];
    this.contexts_enabled = ['minute', 'hour', 'day', 'week', 'month', 'year', 'life'];
    this.rings = [];
    this.styles = {};
    this.canvas = $('#clock')[0];
    this.ctx = this.canvas.getContext('2d');
    window.clock = this;
  }
  Clock.prototype.initialize = function() {
    if (!this.translated) {
      this.ctx.translate(0.5, 0.5);
      this.translated = true;
    }
    this.loadConfig();
    this.setRings();
    this.calculateExpectancy();
    $('body').live('click', function(e) {
      if (e.target.id === 'options-toggle') {
        return $('#options').toggle();
      } else if (e.target.id.match(/clock$|okay$/ || e.target.nodeName === 'body')) {
        return $('#options').hide();
      } else if (e.target.id === 'reset') {
        if (confirm("Delete saved configuration data for this clock?")) {
          delete window.localStorage['config'];
          return window.location.href = window.location.href;
        }
      }
    });
    $('#clock-options').delegate('input, select', 'change click keyup blur', function() {
      if ($(this).attr('type') === 'range') {
        clock.config[$(this)[0].className] = Math.max(Math.min($(this).val(), $(this).attr('max')), $(this).attr('min'));
      } else if ($(this).attr('type') === 'checkbox') {
        clock.config[$(this)[0].className] = $(this).attr('checked') === 'checked';
      } else if ($(this)[0].nodeName.toLowerCase() === 'select') {
        clock.config[$(this)[0].className] = $(this).val();
      }
      clock.setRings();
      return clock.saveConfig();
    });
    $('#personal-options').delegate('input, select', 'change click keyup blur', function() {
      if ($(this)[0].className.match(/gender|bmi|age|birthday/)) {
        clock.config[$(this)[0].className] = $(this).val().toLowerCase();
      } else if ($(this)[0].className.match(/smoker/)) {
        clock.config['smoker'] = !!$(this).attr('checked');
      }
      clock.calculateExpectancy();
      return clock.saveConfig();
    });
    window.onresize = __bind(function() {
      var margin;
      margin = (window.outerHeight - clock.canvas.height) / 4;
      margin = parseInt(Math.max(margin, 0)) + "px";
      return this.canvas.style.marginTop = margin;
    }, this);
    window.onresize();
    this.setTime('all');
    window.setInterval((__bind(function() {
      return this.setTime('all');
    }, this)), 1000);
    return window.setInterval((__bind(function() {
      return this.setTime('minute');
    }, this)), 20);
  };
  Clock.prototype.calculateExpectancy = function() {
    var birthday, current, expectancy;
    if ($('.birthday').val() !== this.config.birthday) {
      current = new Date();
      birthday = new Date(this.config.birthday);
      this.config.age = (current.getTime() - birthday.getTime()) / 86400000 / 365;
    }
    expectancy = {
      'male': 75,
      'female': 80
    }[this.config.gender];
    if (this.config.bmi <= 20) {
      expectancy -= Math.max(20 - this.config.bmi, (20 - this.config.bmi) / 2);
    }
    if (this.config.bmi > 25) {
      expectancy -= Math.min(this.config.bmi - 25, (this.config.bmi - 25) / 2);
    }
    if (this.config.smoker) {
      expectancy -= 10;
    }
    $('.expectancy.output').text(this.config.expectancy = parseInt(expectancy));
    return $('.age.output').text(parseInt(this.config.age * 100) / 100);
  };
  Clock.prototype.loadConfig = function() {
    var config, item, _results;
    try {
      if (window.localStorage['config']) {
        config = JSON.parse(window.localStorage['config']);
      }
    } catch (error) {
      config = false;
    }
    if (config instanceof Object) {
      this.config = config;
      $('#options').hide();
    }
    _results = [];
    for (item in this.config) {
      _results.push($("." + item).length ? $("." + item).attr('type') === 'checkbox' ? $("." + item)[0].checked = !!this.config[item] : $("." + item).val(this.config[item]) : void 0);
    }
    return _results;
  };
  Clock.prototype.saveConfig = function() {
    return window.localStorage['config'] = JSON.stringify(this.config);
  };
  Clock.prototype.setRings = function() {
    var item, _i, _len, _ref, _results;
    _ref = this.contexts_enabled;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      if (this.config['reverse'] === true) {
        this.rings[item] = (this.config.line_width * _i) + this.config.line_width;
      } else {
        this.rings[item] = _len * this.config.line_width - this.config.line_width * _i;
      }
      _results.push(this.styles[item] = "hsl(" + this.config.hue + ", 100%, " + (60 - (_i / (_len * 2)) * 100) + "%)");
    }
    return _results;
  };
  Clock.prototype.draw = function(end, context) {
    var radius, start;
    radius = this.rings[context];
    this.ctx.beginPath();
    this.ctx.lineWidth = this.config.line_width + 2;
    this.ctx.strokeStyle = this.styles[context];
    start = Math.PI * 1.5;
    end -= 15;
    end /= 60;
    end *= Math.PI * 2;
    this.ctx.arc(this.canvas.width / 2, this.canvas.height / 2, radius, end, start, true);
    this.ctx.stroke();
    return this.ctx.closePath();
  };
  Clock.prototype.drawText = function() {
    var font_size, item, line, percent, text, x, x_offset, y, y_offset, _results;
    font_size = 15;
    this.ctx.font = "bold " + (font_size - 2) + "px arial";
    x_offset = 5;
    y_offset = font_size;
    _results = [];
    for (item in this.rings) {
      percent = parseInt((this.styles[item].split(' ')[this.styles[item].split(' ').length - 1]).split(')')[0]);
      if (this.config.lightlabels) {
        this.ctx.fillStyle = 'white';
      } else {
        this.ctx.fillStyle = 'black';
      }
      text = [];
      if (this.config.show_percentage) {
        text.push("" + (parseInt(clock[item] / 60 * 100)) + "%");
      }
      if (this.config.show_labels) {
        text.push(item);
      }
      _results.push((function() {
        var _i, _len, _results2;
        _results2 = [];
        for (_i = 0, _len = text.length; _i < _len; _i++) {
          line = text[_i];
          y = (this.canvas.height / 2 - this.rings[item] + y_offset / (3 - text.length)) - (_i * font_size);
          x = this.canvas.width / 2 + x_offset;
          _results2.push(this.ctx.fillText(line, x, y));
        }
        return _results2;
      }).call(this));
    }
    return _results;
  };
  Clock.prototype.drawGrid = function() {
    this.ctx.beginPath();
    this.ctx.lineWidth = 1;
    this.ctx.strokeStyle = 'black';
    if (this.config.show_grid) {
      this.ctx.moveTo(this.canvas.width / 2, 0);
      this.ctx.lineTo(this.canvas.width / 2, this.canvas.height);
      this.ctx.moveTo(0, this.canvas.height / 2);
      this.ctx.lineTo(this.canvas.width, this.canvas.height / 2);
      this.ctx.strokeStyle = 'rgba(0,0,0,.3)';
      this.ctx.moveTo(0, 0);
      this.ctx.lineTo(this.canvas.width, this.canvas.height);
      this.ctx.moveTo(this.canvas.width, 0);
      this.ctx.lineTo(0, this.canvas.height);
    } else {
      this.ctx.moveTo(this.canvas.width / 2, 0);
      this.ctx.lineTo(this.canvas.width / 2, this.canvas.height / 2);
    }
    this.ctx.stroke();
    return this.ctx.closePath();
  };
  Clock.prototype.changeColors = function() {
    if (!this.config.changecolors) {
      return false;
    }
    clock.config.hue += .01;
    clock.setRings();
    if (clock.config.hue >= 359.99) {
      clock.config.hue = 0;
    }
    return clock.saveConfig();
  };
  Clock.prototype.rotateClock = function(context) {
    var rotate;
    if (context == null) {
      context = 'all';
    }
    if (!this.config.rotate) {
      $('body').removeClass('rotating');
      rotate = 0;
    } else {
      rotate = -parseInt(clock[this.config.rotate_context] * 6 * 1000) / 1000;
      $('body').addClass('rotating');
    }
    return $('#clock').css({
      '-webkit-transform': "rotate(" + rotate + "deg)",
      '-moz-transform': "rotate(" + rotate + "deg)"
    });
  };
  Clock.prototype.drawClock = function(context) {
    var item, _i, _len, _ref;
    if (context == null) {
      context = 'all';
    }
    this.ctx.fillStyle = 'black';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    _ref = this.contexts_enabled;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      if (item === context || 'all') {
        this.draw(clock[item], item);
      }
    }
    if (this.minute > 60) {
      this.minute = 0;
    }
    this.drawGrid(context);
    this.drawText();
    return this.rotateClock(context);
  };
  Clock.prototype.setTime = function(context) {
    var d, d2;
    if (context == null) {
      context = 'all';
    }
    d = new Date();
    d2 = new Date(d.getFullYear(), 0, 1);
    if (context === 'second' || 'all') {
      this.second = ((new Date()).getMilliseconds() / 1000) * 60;
    }
    if (context === 'minute') {
      this.minute = d.getSeconds() + (parseInt(d.getTime() / 10) % parseInt(d.getTime() / 1000)) / 100;
    }
    if (context === 'hour' || 'all') {
      this.hour = d.getMinutes() + (this.minute / 60);
    }
    if (context === 'day' || 'all') {
      this.day = (d.getHours() + (this.hour / 60)) / 24 * 60;
    }
    if (context === 'week' || 'all') {
      this.week = ((d.getDay() - d.getHours() / 24) / 7) * 60;
    }
    if (context === 'month' || 'all') {
      this.month = (d.getDate() / (32 - new Date(d.getYear(), d.getMonth(), 32).getDate())) * 60 - (1 - this.day / 60);
    }
    if (context === 'year' || 'all') {
      this.year = (Math.ceil((d - d2) / 86400000) + this.day / 60) / 365 * 60;
    }
    if (context === 'decade' || 'all') {
      this.decade = (d.getYear() % 10 + ((Math.ceil((d - d2) / 86400000)) / 365) + this.hour / 60 / 365) / 10 * 60;
    }
    if (context === 'life' || 'all') {
      this.life = ((this.config.age * 365 * 24 + (Math.ceil((d - d2) / 86400000)) + this.hour / 60) / (this.config.expectancy * 365 * 24)) * 60;
      if (this.life === 60) {
        $('.age').val(this.config.age = 1);
      }
    }
    if (context === 'century' || 'all') {
      this.century = (((new Date()).getFullYear() % 100) / 100) * 60;
    }
    if (context === 'millenium' || 'all') {
      this.millenium = (((new Date()).getFullYear() % 1000) / 1000) * 60;
    }
    if (context === 'earth' || 'all') {
      this.earth = ((4570000000 + (new Date()).getTime() / 30000000000) / 10000000000) * 60;
    }
    this.drawClock(context);
    if (context === 'all') {
      return this.changeColors();
    }
  };
  return Clock;
})();