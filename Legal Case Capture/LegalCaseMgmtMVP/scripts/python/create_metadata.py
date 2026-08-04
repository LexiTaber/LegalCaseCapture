import os

BASE = "force-app/main/default"

files = {
    # LegalCase__c object
    f"{BASE}/objects/LegalCase__c/LegalCase__c.object-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Legal Case</label>
    <pluralLabel>Legal Cases</pluralLabel>
    <nameField>
        <label>Case Number</label>
        <type>AutoNumber</type>
        <displayFormat>CASE-{0000}</displayFormat>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>Private</sharingModel>
</CustomObject>""",

    f"{BASE}/objects/LegalCase__c/fields/Status__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Status__c</fullName>
    <label>Status</label>
    <type>Picklist</type>
    <valueSet>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Open</fullName><default>true</default><label>Open</label></value>
            <value><fullName>Closed</fullName><default>false</default><label>Closed</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>""",

    f"{BASE}/objects/LegalCase__c/fields/DistrictFiled__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>DistrictFiled__c</fullName>
    <label>District Filed</label>
    <type>Text</type>
    <length>255</length>
</CustomField>""",

    f"{BASE}/objects/LegalCase__c/fields/BoxFolderLink__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>BoxFolderLink__c</fullName>
    <label>Box Folder Link</label>
    <type>Url</type>
</CustomField>""",

    f"{BASE}/objects/LegalCase__c/fields/LeadAttorney__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>LeadAttorney__c</fullName>
    <label>Lead Attorney</label>
    <type>Lookup</type>
    <referenceTo>User</referenceTo>
    <relationshipName>LeadAttorneyLegalCases</relationshipName>
</CustomField>""",

    f"{BASE}/objects/LegalCase__c/fields/SupportStaff__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>SupportStaff__c</fullName>
    <label>Support Staff</label>
    <type>Lookup</type>
    <referenceTo>User</referenceTo>
    <relationshipName>SupportStaffLegalCases</relationshipName>
</CustomField>""",

    # LegalCaseNote__c object
    f"{BASE}/objects/LegalCaseNote__c/LegalCaseNote__c.object-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Legal Case Note</label>
    <pluralLabel>Legal Case Notes</pluralLabel>
    <nameField>
        <label>Legal Case Note Name</label>
        <type>AutoNumber</type>
        <displayFormat>NOTE-{0000}</displayFormat>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ControlledByParent</sharingModel>
</CustomObject>""",

    f"{BASE}/objects/LegalCaseNote__c/fields/LegalCase__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>LegalCase__c</fullName>
    <label>Legal Case</label>
    <type>MasterDetail</type>
    <referenceTo>LegalCase__c</referenceTo>
    <relationshipName>LegalCaseNotes</relationshipName>
    <relationshipOrder>0</relationshipOrder>
</CustomField>""",

    f"{BASE}/objects/LegalCaseNote__c/fields/NoteDate__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>NoteDate__c</fullName>
    <label>Date</label>
    <type>Date</type>
</CustomField>""",

    f"{BASE}/objects/LegalCaseNote__c/fields/Author__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Author__c</fullName>
    <label>Author</label>
    <type>Lookup</type>
    <referenceTo>User</referenceTo>
    <relationshipName>AuthoredCaseNotes</relationshipName>
</CustomField>""",

    f"{BASE}/objects/LegalCaseNote__c/fields/Subject__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Subject__c</fullName>
    <label>Subject</label>
    <type>Text</type>
    <length>255</length>
</CustomField>""",

    f"{BASE}/objects/LegalCaseNote__c/fields/NoteDetail__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>NoteDetail__c</fullName>
    <label>Note Detail</label>
    <type>Html</type>
    <length>32768</length>
    <visibleLines>10</visibleLines>
</CustomField>""",

    f"{BASE}/objects/LegalCaseNote__c/fields/NoteDetailSearch__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>NoteDetailSearch__c</fullName>
    <label>Note Detail Search</label>
    <type>LongTextArea</type>
    <length>32768</length>
    <visibleLines>3</visibleLines>
</CustomField>""",

    # LegalCaseParty__c object
    f"{BASE}/objects/LegalCaseParty__c/LegalCaseParty__c.object-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Legal Case Party</label>
    <pluralLabel>Legal Case Parties</pluralLabel>
    <nameField>
        <label>Legal Case Party Name</label>
        <type>AutoNumber</type>
        <displayFormat>PARTY-{0000}</displayFormat>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ControlledByParent</sharingModel>
</CustomObject>""",

    f"{BASE}/objects/LegalCaseParty__c/fields/LegalCase__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>LegalCase__c</fullName>
    <label>Legal Case</label>
    <type>MasterDetail</type>
    <referenceTo>LegalCase__c</referenceTo>
    <relationshipName>LegalCaseParties</relationshipName>
    <relationshipOrder>0</relationshipOrder>
</CustomField>""",

    f"{BASE}/objects/LegalCaseParty__c/fields/Contact__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Contact__c</fullName>
    <label>Contact</label>
    <type>Lookup</type>
    <referenceTo>Contact</referenceTo>
    <relationshipName>LegalCaseParties</relationshipName>
</CustomField>""",

    f"{BASE}/objects/LegalCaseParty__c/fields/Role__c.field-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Role__c</fullName>
    <label>Role</label>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Client</fullName><default>false</default><label>Client</label></value>
            <value><fullName>Proxy Contact</fullName><default>false</default><label>Proxy Contact</label></value>
            <value><fullName>Partner Org Contact</fullName><default>false</default><label>Partner Org Contact</label></value>
            <value><fullName>Opposing Counsel</fullName><default>false</default><label>Opposing Counsel</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>""",

    # Apex Class meta
    f"{BASE}/classes/LegalCaseNoteHandler.cls-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>64.0</apiVersion>
    <status>Active</status>
</ApexClass>""",

    # Apex Trigger meta
    f"{BASE}/triggers/LegalCaseNoteTrigger.trigger-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>64.0</apiVersion>
    <status>Active</status>
</ApexTrigger>""",

    # Permission Set
    f"{BASE}/permissionsets/LegalCaseMgmt_GeneralAccess.permissionset-meta.xml": """<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Legal Case Mgmt - General Access</label>
    <description>Grants legal team members access to Legal Case Management objects and fields.</description>

    <objectPermissions>
        <object>LegalCase__c</object>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <object>LegalCaseNote__c</object>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <object>LegalCaseParty__c</object>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>

    <fieldPermissions>
        <field>LegalCase__c.Status__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCase__c.DistrictFiled__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCase__c.BoxFolderLink__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCase__c.LeadAttorney__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCase__c.SupportStaff__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCaseNote__c.NoteDate__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCaseNote__c.Author__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCaseNote__c.Subject__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCaseNote__c.NoteDetail__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCaseNote__c.NoteDetailSearch__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCaseParty__c.Contact__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>LegalCaseParty__c.Role__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
</PermissionSet>""",
}

for path, content in files.items():
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Created: {path}")

print("\nDone.")