$(function() {
  $(".bluebox__title--collapsible").click(function(event) {
    var $title = $(event.currentTarget);

    $title.find(".bluebox__expando").toggle();
    $title.next().toggle();
  });

  $(".tattoo__select").click(function(event) {
    // .data() doesn't seem to be hooked up to data- attributes in KoL's version of jQuery.
    $("#tattoo-selected").val($(event.target).attr("data-sigil"));

    $("#tattoo-picker").submit();
  });
});
