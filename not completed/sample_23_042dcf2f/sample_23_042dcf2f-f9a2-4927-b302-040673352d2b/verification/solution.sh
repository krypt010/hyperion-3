#!/bin/sh

# Modify src/app/admin/review-queue/page.tsx
# Using node to perform replacements since python is not available

TARGET_FILE="src/app/admin/review-queue/page.tsx"

cat <<EOF > modify_script.js
const fs = require('fs');

const targetFile = '$TARGET_FILE';
const content = fs.readFileSync(targetFile, 'utf8');

// Replacement 1: Date Column
// Remove status badge and show created_at
const oldDateBlock = \`                                            <TableCell>
                                                {getStatusBadge()}<br/>
                                                {item.reviewed_at && (
                                                    <span className="text-xs text-muted-foreground">
                                                        {format(parseISO(item.reviewed_at), 'Pp')} by {platformUsers.find(u => u.id === item.reviewer_id)?.email || 'Unknown'}
                                                    </span>
                                                )}
                                            </TableCell>\`;

const newDateBlock = \`                                            <TableCell>
                                                {format(parseISO(item.created_at), 'Pp')}
                                            </TableCell>\`;

// Replacement 2: Status Column
// Add reviewed_at date
const oldStatusBlock = \`                                            <TableCell>
                                                {item.status === 'pending' && !item.original_change_details ? (
                                                    <Button variant="outline" size="sm" onClick={() => handleWithdraw(item.id)}>Withdraw</Button>
                                                ) : getStatusBadge()}
                                                {item.status === 'pending' && item.original_change_details && (
                                                    <Badge variant="outline" className="ml-2 bg-green-100 text-green-800">Live</Badge>
                                                )}
                                            </TableCell>\`;

const newStatusBlock = \`                                            <TableCell>
                                                {item.status === 'pending' && !item.original_change_details ? (
                                                    <Button variant="outline" size="sm" onClick={() => handleWithdraw(item.id)}>Withdraw</Button>
                                                ) : getStatusBadge()}
                                                {item.status === 'pending' && item.original_change_details && (
                                                    <Badge variant="outline" className="ml-2 bg-green-100 text-green-800">Live</Badge>
                                                )}
                                                {item.reviewed_at && (
                                                    <div className="text-xs text-muted-foreground mt-1">
                                                        {format(parseISO(item.reviewed_at), 'Pp')}
                                                    </div>
                                                )}
                                            </TableCell>\`;

let newContent = content;

if (newContent.includes(oldDateBlock)) {
    newContent = newContent.replace(oldDateBlock, newDateBlock);
} else {
    console.error("Error: Could not find Date Column block");
    process.exit(1);
}

if (newContent.includes(oldStatusBlock)) {
    newContent = newContent.replace(oldStatusBlock, newStatusBlock);
} else {
    console.error("Error: Could not find Status Column block");
    process.exit(1);
}

fs.writeFileSync(targetFile, newContent);
console.log("Successfully modified " + targetFile);
EOF

node modify_script.js
rm modify_script.js
