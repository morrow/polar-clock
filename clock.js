var clock;
clock = {
  contexts: ["minute", "hour", "day", "week", "month", "year", "decade", "life"],
  config: {
    age: 25,
    gender: "male",
    bmi: 25,
    expectancy: 75,
    hue: 195,
    lightlabels: true,
    smoker: false,
    reverse: false,
    labels: true,
    percentage: true,
    grid: true,
    line_width: 50
  },
  radii: [],
  styles: {},
  initialize: function() {
    this.canvas = $("#clock")[0];
    this.ctx = this.canvas.getContext("2d");
    this.loadConfig();
    this.setRadii();
    this.calculateExpectancy();
    $(".options").live("mouseover", function() {
      return $(".options").addClass("hovered");
    });
    $("#clock").live("mouseover", function() {
      return $(".options").removeClass("hovered");
    });
    $("#clock-options select").live("change click keyup blur", function() {
      var option;
      option = $(this).val().toLowerCase();
      clock.config[option.replace(' ', '').replace(/hide|show/, '').replace('normal', 'reverse').replace('dark', 'light')] = !option.match(/hide|normal|dark/);
      if (option.match(/reverse|normal/)) {
        return clock.setRadii();
      }
    });
    $("[input[type=range]").live("change click keyup blur", function() {
      clock.config[$(this)[0].className] = Math.max(Math.min($(this).val(), $(this).attr("max")), $(this).attr("min"));
      clock.setRadii();
      return clock.saveConfig();
    });
    $("#personal-options").delegate("input, select", "change click keyup blur", function() {
      var value;
      console.log($(this)[0].className);
      console.log($(this).val().toLowerCase());
      value = $(this).val().toLowerCase();
      if ($(this)[0].className.match(/gender|bmi|age/)) {
        clock.config[$(this)[0].className] = value;
      } else if ($(this)[0].className.match(/smoker/)) {
        clock.config["smoker"] = !value.match(/non-smoker/);
      }
      clock.calculateExpectancy();
      return clock.saveConfig();
    });
    window.setInterval('clock.setTime("all")', 1000);
    return window.setInterval('clock.setTime("minute")', 50);
  },
  calculateExpectancy: function() {
    var age, bmi, expectancy, gender, smoker;
    age = clock.config.age;
    bmi = clock.config.bmi;
    gender = clock.config.gender;
    smoker = clock.config.smoker;
    expectancy = {
      "male": 75,
      "female": 80
    }[gender];
    if (bmi <= 20) {
      expectancy -= 3;
    }
    if (bmi > 25) {
      expectancy -= Math.min(bmi - 25, (bmi - 25) / 2);
    }
    if (smoker) {
      expectancy -= 10;
    }
    console.log(expectancy);
    return $(".expectancy.output").text(clock.config.expectancy = Math.round(expectancy));
  },
  loadConfig: function() {
    var config, item, _results;
    try {
      if (window.localStorage["config"]) {
        config = JSON.parse(window.localStorage["config"]);
      }
    } catch (error) {
      config = false;
    }
    if (typeof config === "object") {
      clock.config = config;
    }
    _results = [];
    for (item in clock.config) {
      _results.push($("." + item).length ? $("." + item).val(clock.config[item]) : void 0);
    }
    return _results;
  },
  saveConfig: function() {
    return window.localStorage["config"] = JSON.stringify(clock.config);
  },
  setRadii: function() {
    var item, _i, _len, _ref, _results;
    _ref = this.contexts;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      if (clock.config["reverse"] === true) {
        clock.radii[item] = (this.config.line_width * _i) + this.config.line_width;
      } else {
        clock.radii[item] = _len * this.config.line_width - this.config.line_width * _i;
      }
      _results.push(this.styles[item] = "hsl(" + clock.config.hue + ", 100%, " + (60 - (_i / (_len * 2)) * 100) + "%)");
    }
    return _results;
  },
  draw: function(end, type) {
    var radius, start;
    radius = this.radii[type];
    this.ctx.beginPath();
    this.ctx.lineWidth = this.config.line_width + 2;
    this.ctx.strokeStyle = this.styles[type];
    start = Math.PI * 1.5;
    end -= 15;
    if (end === 45) {
      end = 44.99999;
    }
    end /= 60;
    end *= Math.PI * 2;
    this.ctx.arc(this.canvas.width / 2, this.canvas.height / 2, radius, end, start, true);
    this.ctx.stroke();
    return this.ctx.closePath();
  },
  drawText: function() {
    var item, offset, percent, text, _results;
    this.ctx.font = "bold 13px arial";
    offset = 5;
    _results = [];
    for (item in this.radii) {
      percent = parseInt((this.styles[item].split(' ')[this.styles[item].split(' ').length - 1]).split(')')[0]);
      if (clock.config.lightlabels) {
        this.ctx.fillStyle = "white";
      } else {
        this.ctx.fillStyle = "black";
      }
      text = "";
      if (this.config.labels) {
        text = item;
      }
      if (this.config.labels && this.config.percentage) {
        text += " - ";
      }
      if (this.config.percentage) {
        text += "" + (Math.round(clock[item] / 60 * 100)) + "%";
      }
      _results.push(text ? this.ctx.fillText(text, this.canvas.width / 2 + offset, this.canvas.height / 2 - this.radii[item] + offset) : void 0);
    }
    return _results;
  },
  drawGrid: function() {
    if (!this.config.grid) {
      return false;
    }
    this.ctx.beginPath();
    this.ctx.lineWidth = 1;
    this.ctx.strokeStyle = "rgba(0,0,0,.4)";
    this.ctx.moveTo(this.canvas.width / 2, 0);
    this.ctx.lineTo(this.canvas.width / 2, this.canvas.height);
    this.ctx.moveTo(0, this.canvas.height / 2);
    this.ctx.lineTo(this.canvas.width, this.canvas.height / 2);
    this.ctx.stroke();
    return this.ctx.closePath();
  },
  drawClock: function(context) {
    var item, _i, _len, _ref;
    if (context == null) {
      context = "all";
    }
    this.ctx.fillStyle = "black";
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    _ref = this.contexts;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      if (context === item || "all") {
        this.draw(clock[item], item);
      }
    }
    this.drawText(context);
    this.drawGrid();
    if (this.minute >= 60) {
      return this.minute = 0;
    }
  },
  setTime: function(context) {
    var d, d2;
    if (context == null) {
      context = "all";
    }
    d = new Date();
    d2 = new Date(d.getFullYear(), 0, 1);
    if (context === "minute" || "all") {
      this.minute = d.getSeconds() + (parseInt(d.getTime() / 10) % parseInt(d.getTime() / 1000)) / 100;
    }
    if (context === "hour" || "all") {
      this.hour = d.getMinutes() + (this.minute / 60);
    }
    if (context === "day" || "all") {
      this.day = (d.getHours() + (this.hour / 60)) / 24 * 60;
    }
    if (context === "week" || "all") {
      this.week = ((d.getDay() + d.getHours() / 24) / 7) * 60;
    }
    if (context === "month" || "all") {
      this.month = (d.getDate() / (32 - new Date(d.getYear(), d.getMonth(), 32).getDate())) * 60 + this.day / 60;
    }
    if (context === "year" || "all") {
      this.year = (Math.ceil((d - d2) / 86400000) + this.day / 60) / 365 * 60;
    }
    if (context === "decade" || "all") {
      this.decade = (d.getYear() % 10 + ((Math.ceil((d - d2) / 86400000)) / 365) + this.hour / 60 / 365) / 10 * 60;
    }
    if (context === "life" || "all") {
      this.life = ((clock.config.age * 365 * 24 + (Math.ceil((d - d2) / 86400000)) + this.hour / 60) / (clock.config.expectancy * 365 * 24)) * 60;
      if (this.life === 60) {
        $(".age").val(this.config.age = 1);
      }
    }
    return this.drawClock(context);
  }
};