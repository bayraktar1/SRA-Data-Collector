"""
Some functions for wrangling NCBI metadata
"""
import pandas as pd
import numpy as np
import pycountry_convert as pcc
import pycountry as pc
import re


def clean_string(string):
    """
    Metadata in the NCBI dataframe is inconsistent. To try and extract some useful information we need to clean
    strings after splitting up the metadata to make them readable. This function is used to clean strings that will
    be turned into column names.

    :param string: A string that was split from a longer string on '||'.
    :return: A consistent, all lower case, string that contains no special characters and uses '_' instead of spaces.
    """
    cleaned = string.strip().lower().replace(' ', '_')
    done = ''.join(['_' if c in '/:-,\\' else '' if c in ' ()?' else c for c in cleaned])
    return done


def test_clean_string():
    assert clean_string('geographic location (country and/or sea)') == 'geographic_location_country_and_or_sea'
    assert clean_string('geographic location (latitude)') == 'geographic_location_latitude'
    assert clean_string('host health state') == 'host_health_state'
    assert clean_string('ENA last update') == 'ena_last_update'


def find_columns(keywords, dataframe, exclude_keywords=None):
    """
    This function find keywords in the columns of the NCBI metadata dataframe that we created. We will combine the
    columns downstream into a single column because the metadata is inconsistent and may contain many different
    columns that exist largely out of NaN values.

    :param keywords: Words that will be used to find columns.
    :param dataframe: The dataframe to be searched
    :param exclude_keywords: Keywords to exclude from the search
    :return: A set of strings that contain the column names
    """
    if exclude_keywords is None:
        exclude_keywords = []
    matches = set()

    for column in dataframe.columns:
        keyword_found = any(word in column for word in keywords)
        exclude_keyword_found = any(word in column for word in exclude_keywords)

        if keyword_found and not exclude_keyword_found:
            matches.add(column)

    return matches


def test_find_columns():
    input_df = pd.DataFrame({'geo_location': [1, 2, 3],
                             'geographic': [4, 5, 6],
                             'env': [1, 2, 3],
                             'sample': [1, 2, 3],
                             'location': [1, 2, 3]})

    result = find_columns(['geo', 'location'], input_df)
    assert result == {'geo_location', 'location', 'geographic'}

    result = find_columns(['geo'], input_df, ['geographic'])
    assert result == {'geo_location'}


def combine_columns(df, matches, new_column_name):
    """
    This function combines specified columns from a dataframe. It handles NaN values if they are present. Because the
    columns in the metadata are inconsistent we sweep the columns of the dataframe based on keywords and combine all
    possible useful information into a single column here.

    :param df: Dataframe that contains the columns to be combined
    :param matches: List of strings with column names
    :param new_column_name: Name of the new combined column
    :return: The dataframe with the new column
    """

    def join_non_nan_values(row):
        non_nan_values = [str(val) for val in row if not pd.isna(val)]
        return ','.join(non_nan_values) if non_nan_values else np.nan

    df[new_column_name] = df[matches].apply(join_non_nan_values, axis=1)

    return df


def country_to_continent(country_name):
    """
    Converts the name of a country to the name of the continent it is located in
    :param country_name: String with the name of the country
    :return: String with the name of the continent
    """
    try:
        country_alpha2 = pcc.country_name_to_country_alpha2(country_name)
        continent_code = pcc.country_alpha2_to_continent_code(country_alpha2)
        continent_name = pcc.convert_continent_code_to_continent_name(continent_code)
    except KeyError:
        print(f'ERROR: Country name not recognized by Pycountry. Continent set to NaN!')
        continent_name = np.nan
    return continent_name


def test_country_to_continent():
    assert country_to_continent('Netherlands') == 'Europe'
    assert country_to_continent('United States of America') == 'North America'
    assert country_to_continent('Japan') == 'Asia'
    assert np.isnan(country_to_continent('united states'))
    assert np.isnan(country_to_continent('dsadsad'))


def get_country_name(code):
    """
    This function tries to convert the ISO2 or ISO3 country name to the full country name. If the entered code is not
    a valid ISO2 or ISO3 code the input gets returned :param code: :return:
    """
    try:
        # Try to get country by ISO2 or ISO3 code
        country_code = pc.countries.get(alpha_2=code) or pc.countries.get(alpha_3=code)
        return country_code.name
    except AttributeError:
        # If the code is not a valid ISO2 or ISO3 code, assume it's already a country name
        return code


def clean_geo(location):
    """
    Cleans the combined location column. The function searches for country names in the string and infers the continent.
    :param location: inconsistent string containing names of locations
    :return: Three strings with the continent, country and city or nan values
    """
    # Issue with pycountry package where some country names don't match
    # https://stackoverflow.com/questions/47919846/using-pycountry-to-check-for-name-common-name-official-name
    continents = ['Europe', 'North America', 'South America', 'Asia',
                  'Oceana', 'Antarctica', 'Africa']

    if pd.isna(location):
        continent = np.nan
        country = np.nan
        city = np.nan
    else:
        countries = list(pc.countries)
        country_names = [country.name for country in countries]

        location = re.split('[:,]', location)
        location = set(location)
        location = list(location)

        continent = np.nan
        country = np.nan
        city = np.nan
        found_country = False
        for item in location:
            item = item.strip()
            item = get_country_name(item)
            if item in country_names:
                country = item
                continent = country_to_continent(item)
                found_country = True
            elif item in continents:
                if not found_country:
                    continent = item
            else:
                city = item
    return continent, country, city


def clean_source(string):
    """
    Removes duplicates and numeric strings from the combined isolation source column
    :param string: String with potential duplicate words and numeric strings
    :return: Clean unique strings seperated by commas
    """
    # print(f"Input string: {string}")
    if pd.isna(string):
        result = np.nan
    else:
        string = string.strip().split(',')
        # print(f"After splitting: {string}")
        string = set(string)
        # print(f"After removing duplicates: {string}")
        string = list(string)
        # print(f"After converting to list: {string}")
        # Use list comprehension to filter out strings containing any numeric characters
        result = [item for item in string if not any(char.isdigit() for char in item)]
        # print(f"After filtering: {result}")
        if len(result) == 0:
            # print(result)
            result = np.nan
        else:
            result = ','.join(result)
    # print(f"Final result: {result}")
    # if not result:
    #     print("Final string is empty!=====================")
    return result
