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

################################################################################################################################################


# Create a list to hold the modified data
# modified_data = []

# # Iterate over each row in the data
# for _, row in data.iterrows():
#     # If PREVIOUS_REGIMEN is not '0', create an intermediate row
#     if row['PREVIOUS_REGIMEN'] != '0':
#         modified_data.append({
#             'PATIENTID': row['PATIENTID'],
#             'LINENUMBER': row['LINENUMBER'],
#             'Source': row['PREVIOUS_REGIMEN'],
#             'Target': row['Source'],
#             # Retain other columns as well
#             'LEN_FLAG': row['LEN_FLAG'],
#             'CD38_FLAG': row['CD38_FLAG'],
#             'CD38_EXPOSED_FLAG': row['CD38_EXPOSED_FLAG'],
#             'TRANSPLANT_FLAG': row['TRANSPLANT_FLAG'],
#             'START_YEAR': row['START_YEAR'],
#             'LEN_REFRACTORY_FLAG': row['LEN_REFRACTORY_FLAG']
#         })
    
#     # Add the original row with flow from Source to Target
#     modified_data.append(row.to_dict())

# # Convert the list back to a DataFrame
# modified_data_df = pd.DataFrame(modified_data)


# modified_data_df.to_clipboard()

# data = modified_data_df.copy()

data['START_YEAR'] = data['START_YEAR'].astype(str)


# Initialize the app
app = dash.Dash(__name__)


# Layout of the app
app.layout = html.Div([
html.H1("Patient Regimen Flow"),
html.Div(id='patient-total', style={'fontSize': 24, 'marginBottom': 20}),

html.Label('Select Year:'),
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
    [dash.dependencies.State('year-dropdown', 'value'),
    dash.dependencies.State('line-dropdown', 'value'),
    dash.dependencies.State('transplant-dropdown', 'value'),
    dash.dependencies.State('len-dropdown', 'value'),
    dash.dependencies.State('Len-refractory-dropdown', 'value'),
    dash.dependencies.State('cd38-dropdown', 'value'),
    dash.dependencies.State('cd38-exposed-dropdown', 'value'),
    ],
)

def update_output(n_clicks,year, line, transplant, len_exposed, len_refractory, cd38, cd38_exposed):
    # Step 1: Data Filtering
    filtered_data = data

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
    

    filtered_data["Source"] = filtered_data["Source"].str.replace(f"1", "")
    filtered_data["Source"] = filtered_data["Source"].str.replace(f"2", " ")
    filtered_data["Source"] = filtered_data["Source"].str.replace(f"3", "  ")
    filtered_data["Source"] = filtered_data["Source"].str.replace(f"4", "   ")
    filtered_data["Target"] = filtered_data["Target"].str.replace(f"1", "")
    filtered_data["Target"] = filtered_data["Target"].str.replace(f"2", " ")
    filtered_data["Target"] = filtered_data["Target"].str.replace(f"3", "  ")
    filtered_data["Target"] = filtered_data["Target"].str.replace(f"4", "   ")

    # print("Year:",year, "Line:",line, "Transplant:",transplant, "LEN EXPOSURE:",len_exposed, "LEN REFACT:",len_refractory, "CD38:",cd38,"CD exposure", cd38_exposed)
    

    total_patients = filtered_data.shape[0]  # Get the number of rows in filtered_data
    patient_text = f"Total Patients: {total_patients}"

    # Step 2: Nodes Creation
      # Step 2: Nodes Creation

    # # Extract unique nodes from "Source" and their corresponding CD38_FLAG values
    # source_nodes = filtered_data[['Source', 'CD38_FLAG']].drop_duplicates()

    # # Extract unique nodes from "Target" and their corresponding CD38_FLAG values
    # target_nodes = filtered_data[['Target', 'CD38_FLAG']].drop_duplicates()

    # # Combine the two and drop duplicates
    # all_nodes = pd.concat([source_nodes, target_nodes.rename(columns={'Target': 'Source'})], ignore_index=True).drop_duplicates()

    # # Create a dictionary mapping node labels to colors based on CD38_FLAG
    # node_colors_mapping = {
    #     node: 'red' if ('D' in node or 'Isa' in node) else ('grey' if 'Clinical Study Drug' in node else 'blue') for node in all_nodes['Source']
    # }

    
    nodes = list(set(filtered_data['Source'].unique().tolist() + filtered_data['Target'].unique().tolist()))
    
    # Step 3: Links Creation
    filtered_data['count'] = 1
    links = filtered_data.groupby(['Source', 'Target']).size().reset_index(name='count')

    # colors_node = [node_colors_mapping[node] for node in nodes]
    #     # Define colors for each link combination
    # link_colors = {
    #     ('red', 'blue'): 'rgba(0, 128, 0, 0.8)',   # Green with 0.8 opacity
    #     ('red', 'red'): 'rgba(255, 0, 0, 0.8)',    # Red with 0.8 opacity
    #     ('blue', 'blue'): 'rgba(0, 0, 255, 0.8)',  # Blue with 0.8 opacity
    #     ('blue', 'red'): 'rgba(128, 0, 128, 0.8)'  # Purple with 0.8 opacity
    # }


    # # Create link color assignments based on source and target node colors
    # link_colors_assignment = [
    #     link_colors[(node_colors_mapping[source], node_colors_mapping[target])] 
    #     for source, target in zip(links['Source'], links['Target'])
    # ]


    # Step 4: Visual Customizations
    colors_node = ['rgba({}, {}, {}, 1)'.format(random.randint(0, 255), 
                                                random.randint(0, 255), 
                                                random.randint(0, 255)) for _ in nodes]

    # If we want the random colors 
    # link_colors = ['rgba({}, {}, {}, 0.5)'.format(random.randint(0, 255), 
    #                                               random.randint(0, 255), 
    #                                               random.randint(0, 255)) for _ in range(len(links))]
    
    link_colors = [colors_node[nodes.index(source)] for source in links['Source']]

    def adjust_opacity(color, opacity=0.85):
        # Split the color string and replace the opacity value
        parts = color.split(",")
        parts[3] = " " + str(opacity) + ")"
        return ",".join(parts)

    link_colors = [adjust_opacity(colors_node[nodes.index(source)]) for source in links['Source']]

   
    source = [nodes.index(link) for link in links['Source']]
    target = [nodes.index(link) for link in links['Target']]
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

