string CURRENT_AFTER = "\.gif\" width=50 height=50><p>These are the tattoos you have unlocked:";
string CURRENT_BEFORE = "Current Tattoo:<p><img src=\"https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/sigils/";
string IMAGE_ROOT = "/images/otherimages/sigils/";
string TATTOO_REGEX = "<input type=radio name=newsigil value=\"(\\w+)\">";
string WIKI_ROOT = "http://kol.coldfront.net/thekolwiki/index.php";
string WIKI_SEARCH = "?title=Special:Search&go=Go&search=";

boolean[string] TATTOO_TYPES;    // For inclusion testing.
string[6] TATTOO_TYPES_ORDERED;  // For iteration order.

TATTOO_TYPES_ORDERED[0] = "Unknown";
TATTOO_TYPES_ORDERED[1] = "Custom";
TATTOO_TYPES_ORDERED[2] = "Other";
TATTOO_TYPES_ORDERED[3] = "Item";
TATTOO_TYPES_ORDERED[4] = "Ascension";
TATTOO_TYPES_ORDERED[5] = "Outfit";

foreach index in TATTOO_TYPES_ORDERED TATTOO_TYPES[TATTOO_TYPES_ORDERED[index]] = true;

record tattoo {
  string image;
  string type;
  string label;
  string wiki_page;
};

tattoo[string] TATTOOS;

file_to_map("tattoo_picker.txt", TATTOOS);

buffer render_row(tattoo tattoo, boolean include_type) {
  buffer row;

  row.append("<tr><td><img height=\"50\" width=\"50\" src=\"");
  row.append(IMAGE_ROOT);
  row.append(tattoo.image);
  row.append(".gif\" alt=\"");
  row.append(tattoo.image);
  row.append("\"></td><td><a target=\"_blank\" href=\"");
  row.append(WIKI_ROOT);
  row.append("/");
  row.append(tattoo.wiki_page);
  row.append("\">");

  if (include_type) {
    row.append(tattoo.type);
    row.append(": ");
  }

  row.append(tattoo.label);
  row.append("</a></td></tr>");

  return row;
}

buffer render_tattoo(tattoo tattoo) {
  buffer table;

  table.append("<table>");
  table.append(render_row(tattoo, false));
  table.append("</table>");

  return table;
}

buffer render_bluebox(string title, buffer content) {
  buffer bluebox;

  bluebox.append("<table width=95% cellspacing=0 cellpadding=0>");
  bluebox.append("<tr><td style=\"color: white;\" align=center bgcolor=blue><b>");
  bluebox.append(title);
  bluebox.append("</b></td></tr>");
  bluebox.append("<tr><td style=\"padding: 5px; border: 1px solid blue;\"><center>");
  bluebox.append(content);
  bluebox.append("</center></td></tr>");
  bluebox.append("</tr><tr><td height=4></td></tr>");
  bluebox.append("</table>");

  return bluebox;
}

buffer render_current_tattoo(tattoo current) {
  return render_bluebox("Current Tattoo", render_tattoo(current));
}

buffer render_section(string type, tattoo[string] tattoos) {
  buffer section;

  foreach image in tattoos {
    // Only check for invalid types once (when the first section is rendered).
    if (type == "Unknown" && !(TATTOO_TYPES contains tattoos[image].type)) {
      // TODO: Handle inavlid type.
    } else if (type == tattoos[image].type) {
      section.append(render_tattoo(tattoos[image]));
    }
  }

  if (section.length() == 0) {
    // Empty buffer; no contents, no bluebox.
    return section;
  }

  return render_bluebox(type + " Tattoos", section);
}

buffer render_sections(tattoo[string] tattoos) {
  buffer sections;

  foreach index in TATTOO_TYPES_ORDERED {
    sections.append(render_section(TATTOO_TYPES_ORDERED[index], tattoos));
  }

  return sections;
}

buffer render_table(tattoo[string] tattoos) {
  buffer table;

  table.append("<center><table>");

  foreach image in tattoos {
    table.append(render_row(tattoos[image], true));
  }

  table.append("</table></center");

  return render_bluebox("Tattoos", table);
}

buffer render_content(tattoo current, tattoo[string] tattoos) {
  buffer content;

  content.append("<center>");
  content.append(render_current_tattoo(current));
  content.append(render_sections(tattoos));
  content.append("</center>");

  return content;
}

string get_header(buffer source) {
  return source.substring(0, source.index_of("<body>") + 6);
}

string get_footer(buffer source) {
  return source.substring(source.last_index_of("</body>"));
}

tattoo lookup_tattoo(string image) {
  if (TATTOOS contains image) {
    if (TATTOOS[image].type != "" && TATTOOS[image].label != "" && TATTOOS[image].wiki_page != "") {
      return TATTOOS[image];
    }

    tattoo copy = new tattoo(image, "Unknown", "Mystery tattoo \"" + image + "\"");

    if (TATTOOS[image].wiki_page == "") {
      if (TATTOOS[image].label == "") {
        copy.wiki_page = "File:" + image + ".gif";
      } else {
        copy.wiki_page = WIKI_SEARCH + url_encode(TATTOOS[image].label);
      }
    } else {
      copy.wiki_page = TATTOOS[image].wiki_page;
    }

    if (TATTOOS[image].label != "") {
      copy.label = TATTOOS[image].label;
    }

    if (TATTOOS[image].type != "") {
      copy.type = TATTOOS[image].type;
    }

    return copy;
  }

  return new tattoo(image, "Unknown", "Unrecognized tattoo \"" + image + "\"", "File:" + image + ".gif");
}

tattoo find_current_tattoo(buffer source) {
  int before = source.index_of(CURRENT_BEFORE);
  int after = source.index_of(CURRENT_AFTER);

  if (before > -1 && after > -1) {
    return lookup_tattoo(source.substring(before + CURRENT_BEFORE.length(), after));
  }

  // Can't happen?  Even newly-created characters have a tattoo selected.
  return lookup_tattoo("&lt;missing&gt;");
}

tattoo[string] find_all_tattoos(buffer source) {
  tattoo[string] tattoos;
  string[int][int] matches = group_string(source, TATTOO_REGEX);

  foreach match in matches {
    string image = matches[match][1];

    tattoos[image] = lookup_tattoo(image);
  }

  return tattoos;
}

buffer generate_page(buffer source) {
  buffer page;

  page.append(get_header(source));
  page.append(render_content(find_current_tattoo(source), find_all_tattoos(source)));
  page.append(get_footer(source));

  return page;
}

void main() {
  generate_page(visit_url()).write();
}
