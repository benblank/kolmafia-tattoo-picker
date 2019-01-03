$(function() {
  $("table.bluebox-collapsible tr:first-child td:first-child").click(function(event) {
    var $td = $(event.currentTarget);

    $td.find("span").toggle();
    $td.closest("tr").next().find("center:eq(0)").toggle();
  });

  $(".tattoo__select").click(function(event) {
    // .data() doesn't seem to be hooked up to data- attributes in KoL's version of jQuery.
    $("#tattoo-selected").val($(event.target).attr("data-sigil"));

    $("#tattoo-picker").submit();
  });
});
