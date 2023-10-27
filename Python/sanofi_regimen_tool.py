import dash
from dash import dcc, html
from dash.dependencies import Input, Output
import plotly.graph_objects as go
import pandas as pd
import random

## currently runs but need to correct Linenumber and Year filters but does appear to generate the correct content

# data = pd.read_excel(r"C:\Users\MichaelDiFelice\Documents\Sanofi\Python\Dashboard\Sankey Data Filterd.xlsx")
data = pd.read_csv(r"C:\Users\MichaelDiFelice\Documents\Sanofi\Python\Dashboard\Data\Modified Data\modified_sankey.csv")

################################################################################################################################################

# # Step 1: Create unique nodes for LINENUMBER, REGIMEN, and NEXT_REGIMEN
colors = {}
# # Getting unique values for each column
line_numbers = data['LINENUMBER'].unique()

data['START_YEAR'] = data['START_YEAR'].astype(str)


# Initialize the app
app = dash.Dash(__name__)


# Layout of the app
app.layout = html.Div([
html.H1("Patient Regimen Flow"),
html.Div(id='patient-total', style={'fontSize': 24, 'marginBottom': 20}),
html.Label('Regimen Type:'),
dcc.RadioItems(
    id='regimen-toggle',
    options=[
        {'label': 'Regular Regimen', 'value': 'REGIMEN'},
        {'label': 'Bundled Regimen', 'value': 'BUNDLED_REGIMEN'}
    ],
    value='REGIMEN',  # Default to REGIMEN
    labelStyle={'display': 'block'},  # Display options as block for better readability
    style={'marginBottom': 20}  # Add some margin at the bottom
),
html.Label('Select Lookback Period:'),
dcc.Dropdown(
    id='year-dropdown',
    options=[{'label': year, 'value': year} for year in sorted(data['START_YEAR'].unique(), reverse=True)],
    multi=False,
    value=None
    ),
    
html.Label('Select Line Number:'),
    dcc.Dropdown(
        id='line-dropdown',
        options=[{'label': line, 'value': line} for line in line_numbers],
        multi=False,
        value=None
    ),

html.Label('Transplant Flag:'),
dcc.Dropdown(
    id='transplant-dropdown',
    options=[{'label': 'Transplanted', 'value': 1}, {'label': 'Non Transplanted', 'value': 0}],
    multi=False,
    value=None
),

html.Label('Len Exposure:'),
dcc.Dropdown(
    id='len-dropdown',
    options=[{'label': 'Len Exposed', 'value': 1}, {'label': 'Len Naive', 'value': 0}],
    multi=False,
    value=None
),
html.Label('Len Refractory:'),
dcc.Dropdown(
    id='Len-refractory-dropdown',
    options=[{'label': 'Refractory', 'value': 1}, {'label': 'Non-Ref', 'value': 0}],
    multi=False,
    value=None
),

html.Label('CD38 Flag:'),
dcc.Dropdown(
    id='cd38-dropdown',
    options=[{'label': 'CD38', 'value': 1}, {'label': 'NonCD38', 'value': 0}],
    multi=False,
    value=None
),

html.Label('CD38 Exposure:'),
dcc.Dropdown(
    id='cd38-exposed-dropdown',
    options=[{'label': 'Exposed', 'value': 1}, {'label': 'Naive', 'value': 0}],
    multi=False,
    value=None
),
    
    html.Button('Submit', id='submit-button', n_clicks=0),
    dcc.Loading([
        dcc.Graph(id='sankey-graph')
    ],type='circle')
    
])

# Callback to update the Sankey diagram based on filters
@app.callback(
    Output('sankey-graph', 'figure'),
    Output('patient-total', 'children'),
    [Input('submit-button', 'n_clicks')],
    [dash.dependencies.State('regimen-toggle', 'value'),
    dash.dependencies.State('year-dropdown', 'value'),
    dash.dependencies.State('line-dropdown', 'value'),
    dash.dependencies.State('transplant-dropdown', 'value'),
    dash.dependencies.State('len-dropdown', 'value'),
    dash.dependencies.State('Len-refractory-dropdown', 'value'),
    dash.dependencies.State('cd38-dropdown', 'value'),
    dash.dependencies.State('cd38-exposed-dropdown', 'value'),
    ],
)

def update_output(n_clicks,toggle_value,year, line, transplant, len_exposed, len_refractory, cd38, cd38_exposed):
    # Step 1: Data Filtering
    filtered_data = data

        # Determine which columns to use based on the toggle value
    if toggle_value == 'REGIMEN':
        source_column = 'PREVIOUS_REGIMEN'
        target_column = 'REGIMEN'
    else:  # toggle_value is 'BUNDLED_REGIMEN'
        source_column = 'PREVIOUS_BUNDLE'
        target_column = 'BUNDLED_REGIMEN'

    if not n_clicks:
        return go.Figure(), "Total Patients: 0"
    if year:
        filtered_data = filtered_data[filtered_data['START_YEAR'] == year]
    if line:
        filtered_data = filtered_data[filtered_data['LINENUMBER'] == line]
    if transplant is not None:
        filtered_data = filtered_data[filtered_data['TRANSPLANT_FLAG'] == transplant]
    if len_exposed is not None:
        filtered_data = filtered_data[filtered_data['LEN_FLAG'] == len_exposed]
    if len_refractory is not None:
        filtered_data = filtered_data[filtered_data['LEN_REFRACTORY_FLAG'] == len_refractory]
    if cd38 is not None:
        filtered_data = filtered_data[filtered_data['CD38_FLAG'] == cd38]
    if cd38_exposed is not None:
        filtered_data = filtered_data[filtered_data['CD38_EXPOSED_FLAG'] == cd38_exposed]
    

    filtered_data[source_column] = filtered_data[source_column].str.replace(f"1", "")
    filtered_data[source_column] = filtered_data[source_column].str.replace(f"2", " ")
    filtered_data[source_column] = filtered_data[source_column].str.replace(f"3", "  ")
    filtered_data[source_column] = filtered_data[source_column].str.replace(f"4", "   ")
    filtered_data[target_column] = filtered_data[target_column].str.replace(f"1", "")
    filtered_data[target_column] = filtered_data[target_column].str.replace(f"2", " ")
    filtered_data[target_column] = filtered_data[target_column].str.replace(f"3", "  ")
    filtered_data[target_column] = filtered_data[target_column].str.replace(f"4", "   ")
    

    total_patients = filtered_data.shape[0]  # Get the number of rows in filtered_data
    patient_text = f"Total Patients: {total_patients}"

    
    nodes = list(filtered_data[source_column].unique().tolist()) + list(filtered_data[target_column].unique().tolist())

    # Step 3: Links Creation
    filtered_data['count'] = 1
    links = filtered_data.groupby([source_column, target_column]).size().reset_index(name='count')

    # Step 4: Visual Customizations
    colors_node = ['rgba({}, {}, {}, 1)'.format(random.randint(0, 255), 
                                                random.randint(0, 255), 
                                                random.randint(0, 255)) for _ in nodes]

    link_colors = [colors_node[nodes.index(source)] for source in links[source_column]]

    def adjust_opacity(color, opacity=0.85):
        # Split the color string and replace the opacity value
        parts = color.split(",")
        parts[3] = " " + str(opacity) + ")"
        return ",".join(parts)

    link_colors = [adjust_opacity(colors_node[nodes.index(source)]) for source in links[source_column]]

   
    source = [nodes.index(link) for link in links[source_column]]
    target = [nodes.index(link) for link in links[target_column]]
    value = links['count'].tolist()
    
    fig = go.Figure(
        data=[
            go.Sankey(
                node=dict(
                    pad=15,
                    thickness=60,
                    line=dict(width=0),
                    label=nodes,
                    hovertemplate="LT:%{label}<extra>%{value}</extra>",
                    color=colors_node,
                ),
                link=dict(
                    source=source,
                    target=target,
                    value=value,
                    hovertemplate="LT: %{source.label} → %{target.label}<br>Patient Count: %{value} out of %{source.value:.1,f}<extra></extra>",
                    color=link_colors,
                ),
                textfont=dict(size=20),
            )
        ],
        layout={"height": 1000},
                )

    return fig,patient_text
# Run the app
if __name__ == '__main__':
    app.run_server(debug=True)

