boolean[string] ALPHA_CHARACTERS = $strings[A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z];

// KoLmafia's (HtmlCleaner's) XPath support is too poor to usefully replace these.
string CURRENT_AFTER = "\.gif\" width=50 height=50><p>These are the tattoos you have unlocked:";
string CURRENT_BEFORE = "Current Tattoo:<p><img src=\"https://s3.amazonaws.com/images.kingdomofloathing.com/otherimages/sigils/";

boolean[string] DIGIT_CHARACTERS = $strings[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

// These characters are removed entirely and therefore are not section delimiters.
// This gives us e.g. KNIGHTS-ARMAMENTS instead of KNIGHT-S-ARMAMENTS and helps
// prevent trailing delimiters.
string IGNORED_CHARACTERS = "[\"')]";

string IMAGE_ROOT = "/images/otherimages/sigils/";
int NATURAL_KEY_NUMBER_DIGITS = 4;
string PWD_PATH = "//input[@name=\"pwd\"]/@value";
string SIGIL_PATH = "//input[@name=\"newsigil\"]/@value";
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

void pad_digits(buffer key, int first_digit) {
  int pad_length = NATURAL_KEY_NUMBER_DIGITS - (key.length() - first_digit);

  if (pad_length > 0) {
    for _ from 1 to pad_length {
      key.insert(first_digit, "0");
    }
  }
}

string make_natural_sort_key(string value) {
  // HACK: This converts values into "natural" keys by assuming numerical sections
  // never exceed four digits and padding them out to that length.  It's also very
  // limited in terms of what it recognizes as a number (no signs, commas, etc.).

  // Sanitized string is case-folded (so that casing doesn't affect sort order)
  // and stripped of unhelpful characters (see comment on IGNORED_CHARACTERS).
  string sanitized = create_matcher(IGNORED_CHARACTERS, value.to_upper_case()).replace_all("");

  // The beginning of the value acts as a delimiter, so record it as such.
  string previous_type = "other";

  // This buffer contains the key being built.
  buffer key;

  // The first recorded digit in the current numeric segment.
  int first_digit;

  for index from 0 to sanitized.length() - 1 {
    string character = sanitized.char_at(index);

    // All characters are "other" (and therefore delimiters) unless recognized
    // as a letter or digit.
    string type = "other";

    if (ALPHA_CHARACTERS contains character) {
      type = "alpha";
    } else if (DIGIT_CHARACTERS contains character) {
      type = "digit";
    }

    // When changing segment types, a "pad" action (inserting zeroes at the
    // beginning of a number), a "dash" action (appending a delimiter), and/or
    // a "record" action (tracking the initial digit in a numeric segment) may
    // occur.  Additionally, non-delimiter characters will be written to
    // the key.  The following table tracks which transitions trigger which
    // actions.
    //
    // alpha -> alpha |     |      |        | write
    // alpha -> digit |     | dash | record | write
    // alpha -> other |     | dash |        |
    // digit -> alpha | pad | dash |        | write
    // digit -> digit |     |      |        | write
    // digit -> other | pad | dash |        |
    // other -> alpha |     |      |        | write
    // other -> digit |     |      | record | write
    // other -> other |     |      |        |

    if (previous_type != type) {
      // This is the "pad" action; only occurs when switching FROM a digit.
      if (previous_type == "digit") {
        pad_digits(key, first_digit);
      }

      // This is the "dash" action; only occurs when switching FROM a non-delimiter.
      if (previous_type != "other") {
        key.append("-");
      }

      // This is the "record" action; only occurs when switching TO a digit.
      if (type == "digit") {
        first_digit = key.length();
      }
    }

    // Any non-delimiter is written to the key, regardless of current or previous segment type.
    if (type != "other") {
      key.append(character);
    }

    previous_type = type;
  }

  // If the last segment was numeric, it will not have been padded yet, as
  // there was no segment transition to handle it, so we have to do that now.
  if (previous_type == "digit") {
    pad_digits(key, first_digit);
  }

  // Finally, convert the key to a string, as sorting on buffers doesn't seem to work.
  return to_string(key);
}

buffer render_tattoo(tattoo tattoo, boolean button) {
  buffer div;

  div.append("<div class=tattoo>");

  if (button) {
    div.append("<button class=\"button tattoo__select\" data-sigil=" + tattoo.sigil + ">Select</button>");
    div.append(" ");
  }

  div.append("<img class=\"tattoo__sigil\" src=\"");
  div.append(IMAGE_ROOT);
  div.append(tattoo.sigil);
  div.append(".gif\" alt=\"");
  div.append(tattoo.sigil);
  div.append("\" title=\"");
  div.append(tattoo.sigil);
  div.append("\"> <a target=\"_blank\" href=\"");
  div.append(WIKI_ROOT);
  div.append("/");
  div.append(tattoo.wiki_page);
  div.append("\">");
  div.append(tattoo.label);
  div.append("</a>");
  div.append("</div>");

  return div;
}

buffer render_bluebox(string title, buffer content, boolean is_category) {
  buffer bluebox;

  bluebox.append("<div class=\"bluebox");

  if (is_category) {
    bluebox.append(" bluebox--collapsible bluebox--category");
  }

  bluebox.append("\">");

  bluebox.append("<div class=\"bluebox__title");

  if (is_category) {
    bluebox.append(" bluebox__title--collapsible");
  }

  bluebox.append("\">" + title + ":");

  if (is_category) {
    bluebox.append(" <span class=\"bluebox__title--expando\">(click to open)</span>");
  }

  bluebox.append("</div>");
  bluebox.append("<div class=\"bluebox__contents\">");
  bluebox.append(content);
  bluebox.append("</div>");
  bluebox.append("</div>");

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
  buffer contents;

  contents.append("<div class=formleft>");

  contents.append("<label class=filter>");
  contents.append("<span class=filter__label>Filter: </span>");
  contents.append("<input class=filter__input id=filter></input>");
  contents.append("</label>");

  contents.append("<br>");

  contents.append("<button class=button id=randomize>Select Random Tattoo</button>");

  contents.append("</div>");

  contents.append(render_tattoo(current, false));

  return render_bluebox("Current Tattoo", contents, false);
}

buffer render_section(string type, tattoo[int] tattoos) {
  buffer section;
  int i = 0;

  foreach index in tattoos {
    // Only check for invalid types once (when the first section is rendered).
    if (type == "Unknown" && !(TATTOO_TYPES contains tattoos[index].type)) {
      // TODO: Handle inavlid type.
    } else if (type == tattoos[index].type) {
      section.append(render_tattoo(tattoos[index], true));
    }
  }

  if (section.length() == 0) {
    // Empty buffer; no contents, no bluebox.
    return section;
  }

  return render_bluebox(type + " Tattoos", section, true);
}

buffer render_sections(tattoo[string] tattoos) {
  tattoo[int] list;

  foreach sigil in tattoos {
    list[list.count()] = tattoos[sigil];
  }

  sort list by make_natural_sort_key(value.label);

  buffer sections;

  foreach type in TATTOO_TYPES {
    sections.append(render_section(type, list));
  }

  return sections;
}

string get_header(buffer source) {
  string original_header = source.substring(0, source.index_of("<body>"));
  string css = "<link rel=stylesheet href=\"tattoo_picker.css\">";
  string js = "<script src=\"tattoo_picker.js\"></script>";
  return original_header + css + js + '<body>';
}

string get_footer(buffer source) {
  return source.substring(source.last_index_of("</body>"));
}

string find_pwd(buffer source) {
  return xpath(source, PWD_PATH)[0];
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

  boolean debug = form_fields() contains "debug";

  if (debug) {
    // HACK: This function doesn't return a buffer, so write directly to the
    // page (occurs before proper page content is written).  See also similar
    // lines below.
    write("<p>Debug Mode active (" + KNOWN_TATTOOS.count() + " known tattoos");

    foreach sigil in KNOWN_TATTOOS {
      tattoos[sigil] = lookup_tattoo(sigil);
    }
  }

  int initial_count = tattoos.count();

  foreach _, sigil in xpath(source, SIGIL_PATH) {
    tattoos[sigil] = lookup_tattoo(sigil);
  }

  if (debug) {
    if (initial_count != tattoos.count()) {
      write(" + " + (tattoos.count() - initial_count) + " unrecognized tattoos");
    }

    write(")</p>");
  }

  return tattoos;
}

buffer generate_page(buffer source) {
  buffer page;

  page.append(get_header(source));
  page.append(render_form(find_pwd(source)));
  page.append(render_current_tattoo(find_current_tattoo(source)));
  page.append(render_sections(find_all_tattoos(source)));
  page.append(get_footer(source));

  return page;
}

void main() {
  generate_page(visit_url()).write();
}
