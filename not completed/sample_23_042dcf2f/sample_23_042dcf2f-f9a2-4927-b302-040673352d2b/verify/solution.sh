#!/bin/bash
set -euo pipefail

# Log script execution
echo "Executing solution script to refactor the 'Suggestion History' table."

# Define file path
TARGET_FILE="src/app/admin/review-queue/page.tsx"

# Check if the target file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: Target file not found at $TARGET_FILE" >&2
    exit 1
fi

# Create a backup of the original file
cp "$TARGET_FILE" "$TARGET_FILE.bak"
echo "Backup of $TARGET_FILE created at $TARGET_FILE.bak"

# The original block from the file. It contains 'original_change_details' which causes a build error.
# The content matches the file content from the logs, with correct JSX quotes.
cat > old_table.txt <<'EOF'
                        <Table>
                            <TableHeader><TableRow><TableHead>Date</TableHead><TableHead>Question</TableHead><TableHead>Suggestion</TableHead><TableHead>Status</TableHead></TableRow></TableHeader>
                            <TableBody>
                                {mySuggestions.length > 0 ? mySuggestions.map(item => {
                                     const getStatusBadge = () => {
                                        switch(item.status) {
                                            case 'approved': return <Badge variant="default" className="bg-green-600">Approved</Badge>;
                                            case 'rejected': return <Badge variant="destructive">Rejected</Badge>;
                                            case 'reviewed': return <Badge variant="secondary">Reviewed</Badge>;
                                            case 'withdrawn': return <Badge variant="outline">Withdrawn</Badge>;
                                            default: return <Badge variant="outline">{item.status}</Badge>;
                                        }
                                    }

                                     const questionId = item.change_details?.questionId;
                                     const allMasterQuestions = { ...masterQuestions, ...masterProfileQuestions };
                                     const question = questionId ? allMasterQuestions[questionId] : null;
                                     const questionLabel = question?.label || item.change_details?.questionLabel || 'Unknown Question';

                                     const getGuidanceSummary = () => {
                                        if(!item.change_details.guidanceOverrides) return null;
                                        const changedAnswers = Object.keys(item.change_details.guidanceOverrides);
                                        if (changedAnswers.length === 0) return null;
                                        return `Mapped guidance for ${changedAnswers.length} answer(s): ${changedAnswers.slice(0, 2).map(a => `\"${a}\"`).join(', ')}${changedAnswers.length > 2 ? '...' : ''}`;
                                     };
                                     const guidanceSummary = getGuidanceSummary();

                                    return (
                                        <TableRow key={item.id}>
                                            <TableCell>
                                                {getStatusBadge()}<br/>
                                                {item.reviewed_at && (
                                                    <span className="text-xs text-muted-foreground">
                                                        {format(parseISO(item.reviewed_at), 'Pp')} by {platformUsers.find(u => u.id === item.reviewer_id)?.email || 'Unknown'}
                                                    </span>
                                                )}
                                            </TableCell>
                                            <TableCell>{questionLabel}</TableCell>
                                            <TableCell>
                                                {(item.change_details.optionsToAdd?.length || 0) > 0 && <div className="text-xs">+ Added: {(item.change_details.optionsToAdd || []).map((o: any) => `\"${o.option}\"`).join(', ')}</div>}
                                                {(item.change_details.optionsToRemove?.length || 0) > 0 && <div className="text-xs">- Removed: {(item.change_details.optionsToRemove || []).join(', ')}</div>}
                                                {guidanceSummary && <div className="text-xs">{guidanceSummary}</div>}
                                            </TableCell>
                                            <TableCell>
                                                {item.status === 'pending' && !item.original_change_details ? (
                                                    <Button variant="outline" size="sm" onClick={() => handleWithdraw(item.id)}>Withdraw</Button>
                                                ) : getStatusBadge()}
                                                {item.status === 'pending' && item.original_change_details && (
                                                    <Badge variant="outline" className="ml-2 bg-green-100 text-green-800">Live</Badge>
                                                )}
                                            </TableCell>
                                        </TableRow>
                                    )
                                }) : (
                                    <TableRow><TableCell colSpan={4} className="text-center py-8 text-muted-foreground">You have not submitted any suggestions yet.</TableCell></TableRow>
                                )}
                            </TableBody>
                        </Table>
EOF

# The new, refactored block that fixes the layout and the build error.
cat > new_table.txt <<'EOF'
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead className="w-[180px]">Request Date</TableHead>
                                    <TableHead>Question</TableHead>
                                    <TableHead>Suggestion</TableHead>
                                    <TableHead className="text-right w-[180px]">Status</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {mySuggestions.length > 0 ? mySuggestions.map(item => {
                                     const getStatusBadge = () => {
                                        switch(item.status) {
                                            case 'approved': return <Badge variant="default" className="bg-green-600">Approved</Badge>;
                                            case 'rejected': return <Badge variant="destructive">Rejected</Badge>;
                                            case 'reviewed': return <Badge variant="secondary">Reviewed</Badge>;
                                            case 'withdrawn': return <Badge variant="outline">Withdrawn</Badge>;
                                            default: return <Badge variant="outline">{item.status}</Badge>;
                                        }
                                    }

                                     const questionId = item.change_details?.questionId;
                                     const allMasterQuestions = { ...masterQuestions, ...masterProfileQuestions };
                                     const question = questionId ? allMasterQuestions[questionId] : null;
                                     const questionLabel = question?.label || item.change_details?.questionLabel || 'Unknown Question';

                                     const getGuidanceSummary = () => {
                                        if(!item.change_details.guidanceOverrides) return null;
                                        const changedAnswers = Object.keys(item.change_details.guidanceOverrides);
                                        if (changedAnswers.length === 0) return null;
                                        return `Mapped guidance for ${changedAnswers.length} answer(s): ${changedAnswers.slice(0, 2).map(a => `\"${a}\"`).join(', ')}${changedAnswers.length > 2 ? '...' : ''}`;
                                     };
                                     const guidanceSummary = getGuidanceSummary();

                                    return (
                                        <TableRow key={item.id}>
                                            <TableCell className="font-medium">
                                                {format(parseISO(item.created_at), 'P')}<br/>
                                                <span className="text-xs text-muted-foreground">{format(parseISO(item.created_at), 'p')}</span>
                                            </TableCell>
                                            <TableCell>{questionLabel}</TableCell>
                                            <TableCell>
                                                {(item.change_details.optionsToAdd?.length || 0) > 0 && <div className="text-xs">+ Added: {(item.change_details.optionsToAdd || []).map((o: any) => `\"${o.option}\"`).join(', ')}</div>}
                                                {(item.change_details.optionsToRemove?.length || 0) > 0 && <div className="text-xs">- Removed: {(item.change_details.optionsToRemove || []).join(', ')}</div>}
                                                {guidanceSummary && <div className="text-xs">{guidanceSummary}</div>}
                                            </TableCell>
                                            <TableCell className="text-right">
                                                {item.status === 'pending' ? (
                                                    <Button variant="outline" size="sm" onClick={() => handleWithdraw(item.id)}>Withdraw</Button>
                                                ) : getStatusBadge()}
                                                {item.reviewed_at && (item.status === 'approved' || item.status === 'rejected') && (
                                                    <div className="text-xs text-muted-foreground mt-1">
                                                        {item.status === 'approved' ? 'Approved' : 'Rejected'} {format(parseISO(item.reviewed_at), 'P')}
                                                    </div>
                                                )}
                                            </TableCell>
                                        </TableRow>
                                    )
                                }) : (
                                    <TableRow><TableCell colSpan={4} className="text-center py-8 text-muted-foreground">You have not submitted any suggestions yet.</TableCell></TableRow>
                                )}
                            </TableBody>
                        </Table>
EOF

# Read file contents into environment variables for use in perl
export OLD_BLOCK
OLD_BLOCK=$(<old_table.txt)
export NEW_BLOCK
NEW_BLOCK=$(<new_table.txt)

# Use perl to perform a robust, multi-line replacement of the table block.
# This is much safer than sed for multi-line content with special characters.
perl -i -0777 -pe 's/\Q$ENV{OLD_BLOCK}\E/$ENV{NEW_BLOCK}/' "$TARGET_FILE"

# Check if replacement was successful
if ! grep -q "Request Date" "$TARGET_FILE"; then
    echo "Error: Replacement seems to have failed. 'Request Date' not found in the modified file." >&2
    # Restore from backup
    mv "$TARGET_FILE.bak" "$TARGET_FILE"
    exit 1
fi

# Clean up temporary files
rm -f old_table.txt new_table.txt

echo "Successfully refactored the 'Suggestion History' table in $TARGET_FILE."

exit 0
