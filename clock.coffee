class Clock

  constructor:->
    # configuration
    @config =
      age:              25
      gender:           'male'
      bmi:              25
      expectancy:       75
      hue:              195
      checkcolors:      false
      lightlabels:      true
      smoker:           false
      reverse:          false
      rotate:           false
      rotate_context:   'minute'
      show_labels:      true
      show_percentage:  false
      show_grid:        false
      line_width:       50
    # contexts available to use
    @contexts_available =  ['second', 'minute', 'hour', 'day', 'week', 'month', 'year', 'decade', 'life', 'century', 'millenium', 'earth']
    # enabled contexts
    @contexts_enabled = ['minute', 'hour', 'day', 'week', 'month', 'year', 'life'] 
    # initialize radii array - contains radii for individual rings
    @radii = []
    # styles - contains color information for individual rings
    @styles = {}
    # get canvas
    @canvas = $('#clock')[0]
    # get canvas context
    @ctx = @canvas.getContext('2d')
    # setup window variable
    window.clock = @
  
  initialize:->
    # translate canvas by .5 pixels - trick for better anti-aliasing
    if not @translated
      # translate canvas
      @ctx.translate(0.5, 0.5) 
      # set flag, as ctx.translate operates relatively, not absolutely 
      @translated = true
    # load configuration from localStorage
    @loadConfig()
    # set radii of clock rings
    @setRadii()
    # calculate life expectancy
    @calculateExpectancy()
    # handle click events
    $('body').live 'click', (e)->
      # toggle options when settings button is clicked
      if e.target.id is 'options-toggle'
        $('#options').toggle()
      # hide options when settings canvas or okay button is clicked
      else if e.target.id.match /clock|okay/ or e.target.nodeName is 'body'
        $('#options').hide() 
      # reset options
      else if e.target.id is 'reset'
        # confirm delete
        if confirm "Delete saved configuration data for this clock?"
          # delete localStorage
          delete window.localStorage['config']
          # reload page
          window.location.href = window.location.href
    # handle clock options input
    $('#clock-options').delegate 'input, select', 'change click keyup blur', ->
      # hangle input[type=range] inputs
      if $(@).attr('type') is 'range'
        # use Math.max / Math.min to ensure value is set within acceptable range
        clock.config[$(@)[0].className] = Math.max(Math.min($(@).val(), $(@).attr('max')), $(@).attr('min'))
      # handle checkbox inputs
      else if $(@).attr('type') is 'checkbox'
        clock.config[$(@)[0].className] = $(@).attr('checked') is 'checked'
      # handle select inputs
      else if $(@)[0].nodeName.toLowerCase() is 'select'
        clock.config[$(@)[0].className] = $(@).val()
      # set radii
      clock.setRadii()
      # save configuration
      clock.saveConfig()
    # handle personal options input
    $('#personal-options').delegate 'input, select', 'change click keyup blur', ->
      # gender, bmi, birthday  
      if $(@)[0].className.match /gender|bmi|age|birthday/
        # set config to lowercase value
        clock.config[$(@)[0].className] = $(@).val().toLowerCase()
      # checkbox attributes
      else if $(@)[0].className.match /smoker/
        clock.config['smoker'] = !!$(@).attr('checked')
      # calculate expectancy
      clock.calculateExpectancy()
      # save configuration
      clock.saveConfig()
    # when window is resized, adjust margins to vertically center canvas
    window.onresize = =>
      # initial margin is difference between window height and canvas height / 4
      margin = (window.outerHeight-clock.canvas.height)/4
      # format margin, set minimum to zero 
      margin = parseInt(Math.max(margin, 0)) + "px"
      # set margin
      @canvas.style.marginTop = margin
    # vertically center canvas
    window.onresize()
    # start clock
    @setTime('all')
    # start ticking, update all contexts, colors every second
    window.setInterval ( => @setTime('all') ), 1000
    # start ticking, update minute context 50 times a second
    window.setInterval ( => @setTime('minute') ), 20

  calculateExpectancy: ->
    # source: http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2662372
    if $('.birthday').val() != @config.birthday
      # get current date
      current = new Date()
      # get birth date
      birthday = new Date(@config.birthday)
      # calculate age from current and birth dates
      @config.age = (current.getTime() - birthday.getTime()) / 86400000 / 365
    # initial life expetectancy
    expectancy = {'male':75,'female':80}[@config.gender]
    # if bmi is below healthy range, subtract relative amount from expectancy
    expectancy -= Math.max( 20 - @config.bmi, (20 - @config.bmi) / 2) if @config.bmi <= 20
    # if bmi is above healthy range, subtract relative amount from expectancy
    expectancy -= Math.min(@config.bmi - 25, (@config.bmi - 25) / 2) if @config.bmi > 25
    # subtract 10 if smoker
    expectancy -= 10 if @config.smoker
    # set output for life expectancy
    $('.expectancy.output').text(@config.expectancy = parseInt(expectancy))
    # set output for age
    $('.age.output').text(parseInt(@config.age * 100)/100)

  loadConfig: ->
    # load json configuration from localstorage
    try
      config = JSON.parse window.localStorage['config'] if window.localStorage['config'] 
    catch error
      config = false
    # 
    if config instanceof Object
      @config = config 
      $('#options').hide()
    for item of @config
      if $(".#{item}").length
        if $(".#{item}").attr('type') is 'checkbox'
          $(".#{item}")[0].checked = !!@config[item]
        else
          $(".#{item}").val(@config[item])

  saveConfig: ->
    window.localStorage['config'] = JSON.stringify @config
    
  setRadii: ->
    for item in @contexts_enabled
      if @config['reverse'] is true
        @radii[item] = (@config.line_width * _i) + (@config.line_width)
      else
        @radii[item] = _len * @config.line_width - @config.line_width * _i
      @styles[item] = "hsl(#{@config.hue}, 100%, #{60 - (_i/(_len*2))*100}%)"
        
  draw: (end, type) ->
    radius = @radii[type]
    @ctx.beginPath()
    @ctx.lineWidth = @config.line_width + 2
    @ctx.strokeStyle = @styles[type]
    start = Math.PI * 1.5
    end -= 15
    #end = 44.99999 if end == 45
    end /= 60
    end *= (Math.PI*2)
    @ctx.arc(@canvas.width/2, @canvas.height/2, radius, end, start, true)
    @ctx.stroke()
    @ctx.closePath()

  drawText: (context='all') ->
    font_size = 15
    @ctx.font = "bold #{font_size-2}px arial"
    for item of @radii
      percent = parseInt((@styles[item].split(' ')[@styles[item].split(' ').length-1]).split(')')[0])
      if @config.lightlabels
        @ctx.fillStyle = 'white'
      else
        @ctx.fillStyle = 'black'
      text = []
      text.push "#{parseInt(clock[item]/60*100)}%" if @config.show_percentage
      text.push item if @config.show_labels
      x_offset = (5 / text.length)
      y_offset = font_size
      for line in text
        y = (@canvas.height/2-@radii[item] + y_offset/(3-text.length)) - ((_i) * font_size)
        x = @canvas.width/2 + x_offset
        @ctx.fillText(line, x, y)

  drawGrid: ->
    @ctx.beginPath()
    @ctx.lineWidth = 1
    @ctx.strokeStyle = 'black'
    if @config.show_grid
      @ctx.moveTo(@canvas.width/2, 0)
      @ctx.lineTo(@canvas.width/2, @canvas.height)
      @ctx.moveTo(0, @canvas.height/2)
      @ctx.lineTo(@canvas.width, @canvas.height/2)
      @ctx.strokeStyle = 'rgba(0,0,0,.3)'
      @ctx.moveTo(0, 0)
      @ctx.lineTo(@canvas.width, @canvas.height)
      @ctx.moveTo(@canvas.width, 0)
      @ctx.lineTo(0, @canvas.height)
    else
      @ctx.moveTo(@canvas.width/2, 0)
      @ctx.lineTo(@canvas.width/2, @canvas.height/2)
    @ctx.stroke()
    @ctx.closePath()

  changeColors: ->
    return false if not @config.changecolors
    clock.config.hue += .01
    clock.setRadii()
    clock.config.hue = 0  if clock.config.hue >= 359.99

  rotateClock: (context='all') ->
    if not @config.rotate
      if $('body')[0].className.match /rotating/
        $('body').removeClass 'rotating'
        $('#clock').css
          '-webkit-transform':'rotate(0deg)'
          '-moz-transform':'rotate(0deg)'
    else
      rotate = -parseInt(clock[@config.rotate_context]*6*1000)/1000
      $('body').addClass 'rotating'
      $('#clock').css
        '-webkit-transform':"rotate(#{rotate}deg)"
        '-moz-transform':"rotate(#{rotate}deg)"

  drawClock: (context='all') -> 
    @ctx.fillStyle = 'black'
    @ctx.fillRect(0, 0, @canvas.width, @canvas.height)
    for item in @contexts_enabled
      if item is context or 'all'
        @draw(clock[item], item)
    @minute = 0 if @minute > 60
    @drawGrid(context)
    @drawText(context)
    @rotateClock(context)

  setTime: (context='all') ->
    d = (new Date())
    d2 = new Date(d.getFullYear(), 0, 1)
    if context is 'second' or 'all'
      @second = ((new Date()).getMilliseconds() / 1000) * 60
    if context is 'minute'
      @minute = d.getSeconds() + (parseInt(d.getTime() / 10) % parseInt(d.getTime() / 1000)) / 100
    if context is 'hour' or 'all'
      @hour = d.getMinutes() + (@minute / 60)
    if context is 'day' or 'all'
      @day = (d.getHours() + (@hour / 60)) / 24 * 60
    if context is 'week' or 'all'
      @week = ((d.getDay() - d.getHours() / 24) / 7) * 60
    if context is 'month' or 'all'
      @month = (d.getDate() / (32 - new Date(d.getYear(), d.getMonth(), 32).getDate())) * 60 - (1 - @day/60)
    if context is 'year' or 'all'
      @year = (Math.ceil((d - d2) / 86400000) + @day / 60) / 365 * 60
    if context is 'decade' or 'all'
      @decade = (d.getYear() % 10  + ((Math.ceil((d - d2) / 86400000)) / 365) + @hour / 60 / 365) / 10  * 60
    if context is 'life' or 'all'
      @life = ((@config.age*365*24 + (Math.ceil((d - d2) / 86400000)) + @hour / 60)  / (@config.expectancy*365*24)) * 60
      $('.age').val(@config.age=1) if @life == 60
    if context is 'century' or 'all'
      @century = (((new Date()).getFullYear() % 100) / 100) * 60
    if context is 'millenium' or 'all'
      @millenium = (((new Date()).getFullYear() % 1000) / 1000) * 60
    if context is 'earth' or 'all'
      @earth = ((4570000000 + (new Date()).getTime() / 30000000000) / 10000000000) * 60
    @drawClock(context)
    @changeColors() if context is 'all'
