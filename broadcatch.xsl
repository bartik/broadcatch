<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="hash">
  <xsl:param name="text" select="text()"/>
  <xsl:value-of select="$text"/>
</xsl:template>

<xsl:template name="break">
  <xsl:param name="text" select="text()"/>
  <xsl:choose>
    <xsl:when test="contains($text, '&#xa;')">
      <xsl:call-template name="hash">
        <xsl:with-param name="text" select="substring-before($text, '&#xa;')"/>
      </xsl:call-template>
      <br/>
      <xsl:call-template name="break">
        <xsl:with-param name="text" select="substring-after($text,'&#xa;')"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="hash">
        <xsl:with-param name="text" select="$text"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="BROADCATCH">
  <html>
  <body>
    <xsl:apply-templates/>
  </body>
  </html>
</xsl:template>

<xsl:template match="RUN">
  <table border="1">
    <tr bgcolor="#777777">
      <td><xsl:value-of select="@AT"/></td>
      <td><xsl:value-of select="@PID"/></td>
      <td><xsl:value-of select="@NAME"/></td>
    </tr>
    <xsl:apply-templates/>
  </table>
</xsl:template>

<xsl:template match="ENTRY">
  <xsl:if test="@TYPE != 'TRACE'">
  <tr>
    <td><xsl:value-of select="@TYPE"/></td>
    <td colspan="2"><xsl:call-template name="break"/></td>
  </tr>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
