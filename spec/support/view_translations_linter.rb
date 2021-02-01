# frozen_string_literal: true

# The following class is can be used in RSpecs, Rake Tasks, etc. to lint different view files for untranslated strings.
# Currently supports linting for untranslated strings WITHIN ERB tags and OUTSIDE of ERB tags
# Class is initialized with three params:
# Read View Files - an array of files which have been "read" and stringified such as:
# [File.read("view_filename"), "File.read("view_filename_2")]
# Suggested query is to use a list of changed files from Git as an arguement such as:
# `git diff --name-only origin/master HEAD | grep .html.erb`.strip.split("\n")
# approved Translation Strings - an array of approved strings to ignore, best kept in YML
# Filter Type - Denoting which query you'd like to lint the file for. Currently supported are
# 'in_erb' and 'outside_erb'
class ViewTranslationsLinter
  attr_accessor :filter_type, :non_approved_substrings, :puts_output, :read_view_files, :approved_translation_strings

  def initialize(read_view_files, approved_translation_strings, filter_type)
    @read_view_files = read_view_files
    @approved_translation_strings = approved_translation_strings
    @filter_type = filter_type
    @non_approved_substrings = []
  end

  def all_translations_present?
    return true if read_view_files.blank?
    read_view_files.each do |read_file|
      return false unless no_potential_untranslated_strings?(read_file)
    end
    true
  end

  def no_potential_untranslated_strings?(read_file)
    potential_substrings(read_file).each do |substring|
      non_approved_substring = approved_translation_strings.detect { |approved_substring| substring.downcase.include?(approved_substring.downcase) }
      non_approved_substrings << substring if non_approved_substring.blank?
    end
    return true if non_approved_substrings.blank?
    # Will return nil if non_approved_substrings contains values, and thus return false in #all_translations_present?
    puts(untranslated_warning_message(non_approved_substrings))
  end

  def potential_substrings(read_file)
    case filter_type
    # Other queries for parsing files can be added here
    # when 'in_slim'
    # when 'outside_slim'
    when 'in_erb'
      # The following method will return all code between ERB tags.
      # Since this will return *all* code between ERB tags,
      # Suggested strings to add to approved list:
      # HTML Elements and helper methods not containing text, such as "render"
      # Methods for dates or currency amounts, such as "hired_on", or "current_year"
      # Record Identifiers such as, "model_name_id"
      potential_substrings = read_file.scan(/<%=(.*)%>/).flatten
    when 'outside_erb'
      # The following filter will take the full read HTML.erb file and:
      # Return a string without all HTML/ERB Tags
      # Turn the string into an array, separated at each new line
      # Remove any blank strings from the array
      # Remove any blank space from left and right of array elements
      # Remove blank space to the left and right of sentences
      # Cut the array down to only the uniq elements
      # Remove any array elements which are all special characters (I.E. "!", ":")
      # removes leading and ending extra blankspace, and blank strings, returning an array like:
      # ["list all attributes", "success"]
      #  Further reading: https://stackoverflow.com/a/54405741/5331859
      potential_substrings = ActionView::Base.full_sanitizer.sanitize(read_file).split("\n").reject!(&:blank?).map(&:strip).uniq.reject! do |substring|
        substring.split("").all? { |char| ('a'..'z').to_a.include?(char.downcase) }
      end
    end
    return [] if potential_substrings.blank?
    potential_substrings
  end

  def untranslated_warning_message(non_approved_substrings)
    "The following are potentially untranslated substrings. #{non_approved_substrings.join(', ')}. "\
    "Please modify your ERB and place them in translation helper tags "\
    "with a coorelating translation or add them to the approved string list."
  end
end
