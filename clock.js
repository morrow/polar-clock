var clock;
clock = {
  config: {
    age: 25,
    expectancy: 85,
    reverse: false,
    labels: true,
    percentage: true,
    hue: 195,
    label_color: 90
  },
  radii: [],
  styles: {},
  initialize: function() {
    this.canvas = $("#clock")[0];
    this.ctx = this.canvas.getContext("2d");
    this.line_width = 50;
    this.setRadii();
    this.setTime();
    $("#options").delegate("select", "change click keyup blur", function() {
      var option;
      option = $(this).val().toLowerCase();
      clock.config[option.replace(' ', '').replace(/hide|show/, '').replace('normal', 'reverse')] = !option.match(/hide|normal/);
      if (option.match(/reverse|normal/)) {
        return clock.setRadii();
      }
    });
    return $("#sliders").delegate("input", "change click keyup blur", function() {
      clock.config[$(this)[0].className] = Math.max(Math.min($(this).val(), $(this).attr("max")), $(this).attr("min"));
      return clock.setRadii();
    });
  },
  setRadii: function() {
    var item, _i, _len, _ref, _results;
    _ref = ["minute", "hour", "day", "week", "year", "decade", "life"];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      if (clock.config["reverse"] === true) {
        clock.radii[item] = (this.line_width * _i) + this.line_width;
      } else {
        clock.radii[item] = _len * this.line_width - this.line_width * _i;
      }
      _results.push(this.styles[item] = "hsl(" + clock.config.hue + ", 100%, " + (60 - (_i / (_len * 2)) * 100) + "%)");
    }
    return _results;
  },
  draw: function(end, type) {
    var radius, start;
    radius = this.radii[type];
    this.ctx.beginPath();
    this.ctx.lineWidth = this.line_width + 2;
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
    this.ctx.fonm;
    offset = 5;
    _results = [];
    for (item in this.radii) {
      percent = parseInt((this.styles[item].split(' ')[this.styles[item].split(' ').length - 1]).split(')')[0]);
      this.ctx.fillStyle = "hsl(0, 0%, " + clock.config.label_color + "%)";
      text = "";
      if (this.config.labels) {
        text = item;
      }
      if (this.config.labels && this.config.percentage) {
        text += " - ";
      }
      if (this.config.percentage) {
        text += "" + (parseInt(clock[item] / 60 * 100)) + "%";
      }
      _results.push(text ? this.ctx.fillText(text, this.canvas.width / 2 + offset, this.canvas.height / 2 - this.radii[item] + offset) : void 0);
    }
    return _results;
  },
  drawClock: function() {
    this.ctx.fillStyle = "black";
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    this.draw(this.minute, "minute");
    this.draw(this.hour, "hour");
    this.draw(this.day, "day");
    this.draw(this.week, "week");
    this.draw(this.year, "year");
    this.draw(this.decade, "decade");
    this.draw(this.life, "life");
    this.drawText();
    if (this.minute >= 60) {
      this.minute = 0;
    }
    return window.setTimeout('clock.setTime()', 10);
  },
  setTime: function() {
    var c, d;
    d = new Date();
    this.minute = d.getSeconds() + (parseInt(d.getTime() / 10) % parseInt(d.getTime() / 1000)) / 100;
    this.hour = d.getMinutes() + (this.minute / 60);
    this.day = d.getHours() + (this.hour / 60);
    this.week = (d.getDay() / 7) * 60;
    c = new Date(d.getFullYear(), 0, 1);
    this.year = (Math.ceil((d - c) / 86400000)) / 365 * 60;
    this.decade = (d.getYear() % 10) / 10 * 60;
    this.life = (clock.config.age / clock.config.expectancy) * 60;
    return this.drawClock();
  }
};