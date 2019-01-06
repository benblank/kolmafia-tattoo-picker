$(function() {
  $(".bluebox__title--collapsible").click(function(event) {
    var $title = $(event.currentTarget);

    $title.find(".bluebox__expando").toggle();
    $title.next().toggle();
  });

  $("#filter").keyup(function(event) {
    var filter = event.target.value.toLowerCase();

    $(".tattoo").each(function(_, tattoo) {
      var matches = false;
      var $tattoo = $(tattoo);
      var $button = $tattoo.find("button");

      if (!$button.length) {
        // The current tattoo has no button.
        return;
      }

      // Sigil names ignore trailing "tat" unless it's present in the filter.
      var sigilName = $button.attr("data-sigil").toLowerCase();

      if (sigilName.slice(-3) === "tat") {
        sigilName = sigilName.slice(0, -3);
      }

      if (sigilName.indexOf(filter) !== -1 || filter.indexOf(sigilName) === 0) {
        matches = true;
      }

      // Descriptions match if they contain the filter at all.
      if (!matches && $tattoo.find("a").text().toLowerCase().indexOf(filter) !== -1) {
        matches = true;
      }

      $tattoo.toggle(matches);
    });
  });

  $(".tattoo__select").click(function(event) {
    // .data() doesn't seem to be hooked up to data- attributes in KoL's version of jQuery.
    $("#tattoo-selected").val($(event.target).attr("data-sigil"));

    $("#tattoo-picker").submit();
  });
});
