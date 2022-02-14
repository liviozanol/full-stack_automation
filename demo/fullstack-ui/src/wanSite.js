import * as React from "react";
import {
    List,
    Edit,

    TabbedForm,
    FormTab,
    SimpleFormIterator,
    Datagrid,
    
    TextField,

    SelectInput,
    TextInput,
    ArrayInput,

    Pagination,

    regex,

} from 'react-admin';

import { CustomJobListAside } from './jobList';

//To disable pagination
const PostPagination = props => <Pagination rowsPerPageOptions={[]} {...props} />;
export const WansitesList = props => (
    <List {...props} bulkActionButtons={false} pagination={<PostPagination/>}>
        <Datagrid rowClick="edit">
            <TextField source="tenant" sortable={false} />
            <TextField source="site_id" sortable={false} />
            <TextField source="custom_site_name" label="Site Name" sortable={false} />
            <TextField source="lan_interfaces[0]['ip_address']" label="IP address" sortable={false} />
            <TextField source="lan_interfaces[0]['helper_address']" label="Helper address" sortable={false} />
        </Datagrid>
    </List>
);










const action_choices = [
    {id: "permit",name:"permit"},
    {id: "deny" ,name:"deny"},
];
const protocol_choices = [
    {id: "tcp" ,name:"tcp"},
    {id: "udp" ,name:"udp"},
    {id: "ip"  ,name:"ip"},
    {id: "icmp",name:"icmp"},
    {id: "gre" ,name:"gre"},
];


//Validation fields
const string_regex        = /^([a-zA-Z0-9_\-\s]{1,20}|)$/;
const interface_ip_regex  = /^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\/([1-9]|[1-2][0-9]|3[0-1])$/;
const helper_address_regex= /^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/;

const acl_action_regex    = /^(permit|deny)$/;
const acl_src_dst_regex   = /^(^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\/([1-9]|[1-2][0-9]|3[0-2])$|any$)/;
const acl_protocol_regex  = /^(tcp|udp|icmp|ip|gre)$/;
const acl_port_regex      = /^[0-9]{1,5}-[0-9]{1,5}$|^(?![\s\S])$|^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/;

const validateStringRegex     = regex(string_regex,         'Field must match regex '+string_regex);
const validateInterfaceRegex  = regex(interface_ip_regex,   'Must be IP/MASK');
const validateHelperRegex     = regex(helper_address_regex, 'Invalid IP Address');
const validateACLActionRegex  = regex(acl_action_regex,     'Action must be either permit or deny');
const validateSrcDstRegex     = regex(acl_src_dst_regex,    'Src/Dst must be IP/MASK or "any"');
const validateProtocolRegex   = regex(acl_protocol_regex,   'Invalid Protocol');
const validatePortRegex       = regex(acl_port_regex,       'Invalid Port. Should be single port or range (eg.: 80 or 80-443)');

export const WansiteEdit = props => {
    return (
    <Edit {...props} mutationMode="pessimistic" aside={<CustomJobListAside/>}>
        <TabbedForm redirect="edit">
            <FormTab label="summary">
                <TextField source="site_id" label="Site"/>
                <TextInput source="custom_site_name" validate={validateStringRegex} label="Site Name" />
            </FormTab>
            <FormTab label="interface data">
                <TextField label="Router Interface" source="lan_interfaces[0]['interface_name']" />
                <TextInput label="IP Address" validate={validateInterfaceRegex} source="lan_interfaces[0]['ip_address']" />
                <TextInput label="Interface Description" validate={validateStringRegex} source="lan_interfaces[0]['description']" />
                <TextInput label="Helper Address" validate={validateHelperRegex} source="lan_interfaces[0]['helper_address']" />
            </FormTab>
            <FormTab label="input ACL">
                <ArrayInput label="" source="lan_interfaces[0]['in_acl']">
                    <SimpleFormIterator>
                        <SelectInput label="Action" validate={validateACLActionRegex} source="action" choices={action_choices}/>
                        <TextInput label="Src Address" validate={validateSrcDstRegex} source="src" />
                        <TextInput label="Dst Address" validate={validateSrcDstRegex} source="dst" />
                        <SelectInput label="Protocol" validate={validateProtocolRegex} source="protocol" choices={protocol_choices}/>
                        <TextInput label="Port" initialValue="" validate={validatePortRegex} source="port" />
                    </SimpleFormIterator>
                </ArrayInput>
            </FormTab>
            <FormTab label="Output ACL">
                <ArrayInput label="" source="lan_interfaces[0]['out_acl']">
                    <SimpleFormIterator>
                        <SelectInput label="Action" validate={validateACLActionRegex} source="action" choices={action_choices}/>
                        <TextInput label="Src Address" validate={validateSrcDstRegex} source="src" />
                        <TextInput label="Dst Address" validate={validateSrcDstRegex} source="dst" />
                        <SelectInput label="Protocol" validate={validateProtocolRegex} source="protocol" choices={protocol_choices}/>
                        <TextInput label="Port" validate={validatePortRegex} source="port" />
                    </SimpleFormIterator>
                </ArrayInput>
            </FormTab>

        </TabbedForm>
    </Edit>
    )
};


