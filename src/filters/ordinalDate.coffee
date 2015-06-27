'use strict'

app = angular.module 'launcher'

app.filter 'ordinalDate', ($filter) ->
  (input) ->
    year = $filter('date')(new Date(input), 'yyyy')
    month = $filter('date')(new Date(input), 'MMM')
    day = new Date(input).getDate()

    ordinals = ['th', 'st', 'nd', 'rd']
    ordinal = (ordinals[(day - 20) % 10] || ordinals[day] || ordinals[0])

    "#{month} #{day}#{ordinal} #{year}"
