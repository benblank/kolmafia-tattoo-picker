$(function() {
  $("button.tattoo-select").click(function(event) {
    // .data() doesn't seem to be hooked up to data- attributes in KoL's version of jQuery.
    $("#tattoo-selected").val($(event.target).attr("data-sigil"));

    $("#tattoo-picker").submit();
  });
});
