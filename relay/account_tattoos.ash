string CURRENT_AFTER = "\.gif\" width=50 height=50><p>These are the tattoos you have unlocked:";
string CURRENT_BEFORE = "Current Tattoo:<p><img src=\"/images/otherimages/sigils/";
string IMAGE_ROOT = "/images/otherimages/sigils/";
string TATTOO_REGEX = "<input type=radio name=newsigil value=\"(\\w+)\">";
string WIKI_ROOT = "http://kol.coldfront.net/thekolwiki/index.php";
string WIKI_SEARCH = "?title=Special:Search&go=Go&search=";

string[6] TATTOO_TYPES;

TATTOO_TYPES[0] = "Unknown";
TATTOO_TYPES[1] = "Custom";
TATTOO_TYPES[2] = "Other";
TATTOO_TYPES[3] = "Ascension";
TATTOO_TYPES[4] = "Item";
TATTOO_TYPES[5] = "Outfit";

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

buffer render_table(tattoo[string] tattoos) {
  buffer table;

  table.append("<table width=\"95%\" cellspacing=\"0\" cellpadding=\"0\">");
  table.append("<td style=\"color: white;\" align=center bgcolor=blue colspan=2><b>Tattoos</b></td></tr>");

  foreach image in tattoos {
    table.append(render_row(tattoos[image], true));
  }

  table.append("</table>");

  return table;
}

buffer render_content(tattoo current, tattoo[string] tattoos) {
  buffer content;

  content.append("<center>");
  content.append(render_table(tattoos));
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
  int start = source.index_of(CURRENT_BEFORE) + CURRENT_BEFORE.length();
  int end = source.index_of(CURRENT_AFTER);

  if (start > -1 && end > -1) {
    return lookup_tattoo(source.substring(start, end));
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
