string CURRENT_AFTER = "\.gif\" width=50 height=50><p>These are the tattoos you have unlocked:";
string CURRENT_BEFORE = "Current Tattoo:<p><img src=\"https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/sigils/";
string IMAGE_ROOT = "/images/otherimages/sigils/";
string PWD_PATTERN = "<input type=hidden name=pwd value='(\\w+)'>";
string TATTOO_REGEX = "<input type=radio name=newsigil value=\"(\\w+)\">";
string WIKI_ROOT = "http://kol.coldfront.net/thekolwiki/index.php";
string WIKI_SEARCH = "?title=Special:Search&go=Go&search=";

boolean[string] TATTOO_TYPES = $strings[
  Unknown,
  Custom,
  Other,
  Item,
  Ascension,
  Outfit,
];

record tattoo {
  string sigil;
  string type;
  string label;
  string wiki_page;
};

tattoo[string] KNOWN_TATTOOS;

file_to_map("tattoo_picker.txt", KNOWN_TATTOOS);

tattoo lookup_tattoo(string sigil) {
  if (KNOWN_TATTOOS contains sigil) {
    if (KNOWN_TATTOOS[sigil].type != "" && KNOWN_TATTOOS[sigil].label != "" && KNOWN_TATTOOS[sigil].wiki_page != "") {
      return KNOWN_TATTOOS[sigil];
    }

    tattoo copy = new tattoo(sigil, "Unknown", "Mystery tattoo \"" + sigil + "\"");

    if (KNOWN_TATTOOS[sigil].wiki_page == "") {
      if (KNOWN_TATTOOS[sigil].label == "") {
        copy.wiki_page = "File:" + sigil + ".gif";
      } else {
        copy.wiki_page = WIKI_SEARCH + url_encode(KNOWN_TATTOOS[sigil].label);
      }
    } else {
      copy.wiki_page = KNOWN_TATTOOS[sigil].wiki_page;
    }

    if (KNOWN_TATTOOS[sigil].label != "") {
      copy.label = KNOWN_TATTOOS[sigil].label;
    }

    if (KNOWN_TATTOOS[sigil].type != "") {
      copy.type = KNOWN_TATTOOS[sigil].type;
    }

    return copy;
  }

  return new tattoo(sigil, "Unknown", "Unrecognized tattoo \"" + sigil + "\"", "File:" + sigil + ".gif");
}

buffer render_tattoo(tattoo tattoo, boolean button) {
  buffer table;

  table.append("<table>");
  table.append("<tr>");

  if (button) {
    table.append("<td valign=center>");
    table.append("<button class=\"button tattoo-select\" data-sigil=" + tattoo.sigil + ">Select</button>");
    table.append("</td>");
  }

  table.append("<td><img height=\"50\" width=\"50\" src=\"");
  table.append(IMAGE_ROOT);
  table.append(tattoo.sigil);
  table.append(".gif\" alt=\"");
  table.append(tattoo.sigil);
  table.append("\" title=\"");
  table.append(tattoo.sigil);
  table.append("\"></td><td><a target=\"_blank\" href=\"");
  table.append(WIKI_ROOT);
  table.append("/");
  table.append(tattoo.wiki_page);
  table.append("\">");
  table.append(tattoo.label);
  table.append("</a></td></tr>");
  table.append("</table>");

  return table;
}

buffer render_bluebox(string title, buffer content, boolean collapsible) {
  buffer bluebox;

  bluebox.append("<table");

  if (collapsible) {
    bluebox.append(" class=bluebox-collapsible");
  }

  bluebox.append(" width=95% cellspacing=0 cellpadding=0>");
  bluebox.append("<tr><td style=\"color: white;");

  if (collapsible) {
    bluebox.append(" cursor: pointer;");
  }

  bluebox.append("\" align=center bgcolor=blue><b>");
  bluebox.append(title + ":");

  if (collapsible) {
    bluebox.append(" <span style=\"display: none; font-size: .8em; padding-left: 1em;\">");
    bluebox.append("(click to open)");
    bluebox.append("</span>");
  }

  bluebox.append("</b></td></tr>");
  bluebox.append("<tr><td style=\"padding: 5px; border: 1px solid blue;\"><center>");
  bluebox.append(content);
  bluebox.append("</center></td></tr>");
  bluebox.append("</tr><tr><td height=4></td></tr>");
  bluebox.append("</table>");

  return bluebox;
}

buffer render_form(string pwd) {
  buffer form;

  form.append("<form method=post id=tattoo-picker>");
  form.append("<input type=hidden name=pwd value='" + pwd + "'>");
  form.append("<input type=hidden name=newsigil id=tattoo-selected>");
  form.append("</form>");

  return form;
}

buffer render_current_tattoo(tattoo current) {
  return render_bluebox("Current Tattoo", render_tattoo(current, false), false);
}

buffer render_section(string type, tattoo[string] tattoos) {
  buffer section;
  int i = 0;

  foreach sigil in tattoos {
    // Only check for invalid types once (when the first section is rendered).
    if (type == "Unknown" && !(TATTOO_TYPES contains tattoos[sigil].type)) {
      // TODO: Handle inavlid type.
    } else if (type == tattoos[sigil].type) {
      if (i % 3 == 0) {
        section.append("<tr>");
      }

      section.append("<td>");
      section.append(render_tattoo(tattoos[sigil], true));
      section.append("</td>");

      if (i++ % 3 == 2) {
        section.append("</tr>");
      }
    }
  }

  if (section.length() == 0) {
    // Empty buffer; no contents, no bluebox.
    return section;
  }

  section.insert(0, "<table width=100%>");
  section.append("</table>");

  return render_bluebox(type + " Tattoos", section, true);
}

buffer render_sections(tattoo[string] tattoos) {
  buffer sections;

  foreach type in TATTOO_TYPES {
    sections.append(render_section(type, tattoos));
  }

  return sections;
}

string get_header(buffer source) {
  return source.substring(0, source.index_of("<body>") + 6);
}

string get_footer(buffer source) {
  return source.substring(source.last_index_of("</body>"));
}

string find_pwd(buffer source) {
  matcher pwd = create_matcher(PWD_PATTERN, source);

  pwd.find();

  return pwd.group(1);
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

  if (form_fields() contains "debug") {
    // HACK: This function doesn't return a buffer, so write directly to the
    // page (occurs before proper page content is written).
    write("<p>Debug Mode active (" + KNOWN_TATTOOS.count() + " known tattoos)</p>");

    foreach sigil in KNOWN_TATTOOS {
      tattoos[sigil] = lookup_tattoo(sigil);
    }
  }

  string[int][int] matches = group_string(source, TATTOO_REGEX);

  foreach match in matches {
    string sigil = matches[match][1];

    tattoos[sigil] = lookup_tattoo(sigil);
  }

  return tattoos;
}

buffer generate_page(buffer source) {
  buffer page;

  page.append(get_header(source));
  page.append("<center>");
  page.append(render_form(find_pwd(source)));
  page.append(render_current_tattoo(find_current_tattoo(source)));
  page.append(render_sections(find_all_tattoos(source)));
  page.append("</center>");
  page.append("<script src=\"tattoo_picker.js\"></script>");
  page.append(get_footer(source));

  return page;
}

void main() {
  generate_page(visit_url()).write();
}
