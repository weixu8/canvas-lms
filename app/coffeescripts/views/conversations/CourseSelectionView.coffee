define [
  'i18n!conversations'
  'underscore'
  'Backbone'
  'jst/conversations/courseOptions'
  'use!vendor/bootstrap/bootstrap-dropdown'
  'use!vendor/bootstrap-select/bootstrap-select'
], (I18n, _, {View, Collection}, template) ->

  class CourseSelectionView extends View
    events:
      'change': 'onChange'

    initialize: () ->
      super()
      if !@options.defaultOption then @options.defaultOption = I18n.t('all_courses', 'All Courses')
      @$el.addClass('show-tick')
      @$el.selectpicker(useSubmenus: true).next()
        .on('mouseover', @loadAll)
        .find('.dropdown-toggle').on('focus', @loadAll)
      @options.courses.favorites.on('reset', @render)
      @options.courses.all.on('reset', @render)
      @render()

    render: () =>
      super()
      more = []
      concluded = []
      @options.courses.all.each((course) =>
        if @options.courses.favorites.get(course.id) then return
        collection = if course.get('workflow_state') == 'completed' then concluded else more
        collection.push(course.toJSON())
      )
      data = 
        defaultOption: @options.defaultOption,
        favorites: @options.courses.favorites.toJSON(),
        more: more,
        concluded: concluded
      @truncate_course_name_data(data)
      @$el.html(template(data))
      @$el.selectpicker('refresh')
      if !@renderValue() then @loadAll()

    loadAll: () =>
      all = @options.courses.all
      if all._loading then return
      all.fetch()
      all._loading = true

    _value: ''
    setValue: (value) ->
      @_value = value || ''
      @renderValue()
      @triggerEvent()

    renderValue: () ->
      @$el.selectpicker('val', @_value)
      return @$el.val() == @_value

    onChange: () ->
      @_value = @$el.val()
      @triggerEvent()

    triggerEvent: () ->
      @trigger('course', name: @$el.find(':selected').text().trim(), id: @_value)

    focus: ->
      @$el.next().find('.dropdown-toggle').focus()

    truncate_course_name_data: (course_data) ->
      _.each(['favorites', 'more', 'concluded'], (key) =>
        @truncate_course_names(course_data[key])
        )

    truncate_course_names: (courses) ->
      _.each(courses, @truncate_course)

    truncate_course: (course) =>
      name = course['name']
      truncated = @middle_truncate(name)
      unless name == truncated
        course['truncated_name'] = truncated

    middle_truncate: (name) ->
      # This implementation ignores non-BMP character encoding issues in favor of simplicity
      if name.length > 25
        name.slice(0, 10) + "&hellip;" + name.slice(-10)
      else
        name
