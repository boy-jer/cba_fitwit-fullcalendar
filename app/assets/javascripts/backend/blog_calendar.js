$(document).ready(function() {

    var date = new Date();
    var d = date.getDate();
    var m = date.getMonth();
    var y = date.getFullYear();
    var location_id = window.location.pathname.split("/")[3];

    $('#calendar').fullCalendar({
        editable: true,
        header: {
            left: 'prev,next today',
            center: 'title',
            right: 'month,agendaWeek,agendaDay'
        },
        defaultView: 'month',
        height: 500,
        slotMinutes: 15,

        loading: function(bool) {
            if (bool)
                $('#loading').show();
            else
                $('#loading').hide();
        },

        // a future calendar might have many sources.
        eventSources: [
            {
                url: '/backend/locations/' + location_id + '/events',
                color: 'red',
                textColor: 'white',
                ignoreTimezone: false
            },
            {
                url: '/calendar/all_camp_events/' + location_id,
                color: 'green',
                textColor: 'white',
                ignoreTimezone: false
            }
        ],

        timeFormat: 'h:mm t{ - h:mm t} ',
        dragOpacity: "0.5",

        //http://arshaw.com/fullcalendar/docs/event_ui/eventDrop/
        eventDrop: function(event, dayDelta, minuteDelta, allDay, revertFunc) {
           updateEvent(event, location_id);
        },

        // http://arshaw.com/fullcalendar/docs/event_ui/eventResize/
        eventResize: function(event, dayDelta, minuteDelta, revertFunc) {
            updateEvent(event, location_id);
        },

        // http://arshaw.com/fullcalendar/docs/mouse/eventClick/
        eventClick: function(event, jsEvent, view) {
            alert('test');
        }
    });
});

function updateEvent(the_event, loc_id) {
    $.update(
        '/backend/locations/' + loc_id + '/events/' + the_event.id,
        { event: { title: the_event.title,
            starts_at: "" + the_event.start,
            ends_at: "" + the_event.end,
            description: the_event.description
        }
        },
        function (response) {
            alert('successfully updated task.');
        }
    );
}
;